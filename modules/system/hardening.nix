# modules/system/hardening.nix
################################################################################
# macOS security hardening (ERNW Hardening Guide — macOS 26 Tahoe). Consolidates
# the firewall, Siri/AI disable, and auto-update settings that used to live in
# basic.nix/desktop.nix, and adds the guide's implementable controls. Native
# nix-darwin options are used where they exist; the rest are applied imperatively
# in a root activation script (each guarded so activation never aborts).
#
# NOT handled here (no declarative mechanism — apply/verify manually):
#   * Enable FileVault / SIP / Authenticated Root / Secure Boot Full (Recovery or
#     GUI; already enabled on this host — verify with `fdesetup status`,
#     `csrutil status`, `bputil -d`).
#   * "Allow accessories to connect: Ask" — no scriptable key (MDM only); already
#     the secure default on Apple Silicon laptops.
#   * Time Machine backup encryption; Apple-Watch-unlock + extra Touch ID uses;
#     iCloud / passkey-sync / proximity-password config profiles (MDM).
#   * Recurring audits: system extensions, LaunchDaemons, login items, setuid.
# Declined (per design discussion): block-all-incoming, AirDrop, Handoff,
#   password policy, disabling Location Services / Lockdown Mode / iCloud,
#   disabling Remote Login (kept for Tailscale ssh-in).
# Account separation (mandatory) is scaffolded separately under modules/users/.
################################################################################
{ ... }:
{
  flake.aspects =
    { aspects, ... }:
    {
      hardening = {
        # darwin.siri.* options come from the options.base aspect. Including it
        # here is safe even though basic also does: resolved aspects are deduped
        # by a stable key (see _aspects/resolve-aspect.nix).
        includes = with aspects; [ options.base ];

        darwin =
          {
            config,
            lib,
            ...
          }:
          let
            primaryUser = config.system.primaryUser;
            asUser = command: "sudo -u ${primaryUser} ${command} || true";

            # Apple launchd services disabled to shrink the network attack
            # surface. All are off/on-demand by default; disabling persists and is
            # reversible with `launchctl enable system/<service>`. nfsd is included
            # but may break NFS-based VM/dev file sharing (docker/vagrant).
            disabledServices = [
              "com.apple.screensharing"
              "com.apple.smbd" # File sharing (SMB)
              "com.apple.AEServer" # Remote AppleEvents
              "com.apple.RemoteManagementDaemon" # Apple Remote Desktop
              "com.apple.AssetCacheManagerDaemon" # Content caching
              "com.apple.ODSAgent" # Media sharing
              "com.apple.tftpd"
              "com.apple.nfsd"
              "org.apache.httpd"
              "com.apple.uucp"
            ];
          in
          {
            # Firewall: enabled + stealth, and NOT auto-allowing signed software to
            # listen (more prompts, but signed malware can't silently accept
            # inbound connections).
            networking.applicationFirewall = {
              enable = true;
              enableStealthMode = true;
              allowSigned = false;
              allowSignedApp = false;
            };

            # Apple Intelligence / Siri off (zero-trust on external compute).
            darwin.siri = {
              enable = false;
              enableAppleIntelligence = false;
            };

            system.defaults = {
              # Login window: no guest, and name+password fields instead of a
              # clickable user list.
              loginwindow = {
                GuestEnabled = false;
                SHOWFULLNAME = true;
              };

              # Lock immediately; require the password the moment the screen locks.
              screensaver = {
                askForPassword = true;
                askForPasswordDelay = 0;
              };

              # Auto-install macOS updates (the rest of the chain is set in the
              # activation script since those keys have no native option).
              SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;

              # Per-user defaults nix-darwin writes into the primary user's domain.
              CustomUserPreferences = {
                "com.apple.CrashReporter".DialogType = "none";
                "com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;
                "com.apple.desktopservices" = {
                  DSDontWriteNetworkStores = true;
                  DSDontWriteUSBStores = true;
                };
                "com.apple.security.FIDO2".TouchIDRequired = true;
              };
            };

            # sudo: biometric auth, no grace period, per-tty tickets.
            security.pam.services.sudo_local = {
              enable = true;
              touchIdAuth = true;
            };
            environment.etc."sudoers.d/hardening".text = ''
              Defaults timestamp_timeout=0
              Defaults tty_tickets
            '';

            # SSH client: restrict to strong modern algorithms (incl. post-quantum
            # mlkem768). home-manager now owns ~/.ssh/config — an existing file is
            # moved to .backup; migrate personal Host entries into nix.
            home-manager.users.${primaryUser}.programs.ssh = {
              enable = true;
              enableDefaultConfig = false;
              settings."*" = {
                Ciphers = "chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr";
                MACs = "hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com";
                KexAlgorithms = "mlkem768x25519-sha256,sntrup761x25519-sha512@openssh.com,sntrup761x25519-sha512,curve25519-sha256@libssh.org,curve25519-sha256,diffie-hellman-group18-sha512,diffie-hellman-group16-sha512";
                HostKeyAlgorithms = "ssh-ed25519-cert-v01@openssh.com,ssh-ed25519,sk-ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,rsa-sha2-512,rsa-sha2-256";
              };
            };

            # Controls without a native option or a system-domain target, applied
            # as root after activation. PlistBuddy/defaults paths are guarded so a
            # missing key or service never aborts the rebuild.
            system.activationScripts.postActivation.text = lib.mkAfter ''
              echo "[hardening] applying imperative macOS hardening" >&2

              # Gatekeeper (already on by default; enforce explicitly).
              /usr/sbin/spctl --global-enable || true

              # Disable unused sharing/legacy services.
              ${lib.concatMapStringsSep "\n              " (
                service: "launchctl disable system/${service} || true"
              ) disabledServices}
              /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -deactivate -stop || true
              /usr/bin/AssetCacheManagerUtil deactivate || true
              /usr/sbin/cupsctl --no-share-printers || true

              # Power Nap / wake-on-network off.
              /usr/bin/pmset -a womp 0 || true
              /usr/sbin/systemsetup -setwakeonnetworkaccess off || true

              # Touch ID: fall back to the password after 30 min (default is 2 days).
              /usr/bin/bioutil -w -s --btimeout 1800 || true

              # Analytics: don't auto-submit crash/diagnostic data.
              defaults write "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory" AutoSubmit -bool false || true
              defaults write "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory" ThirdPartyDataSubmit -bool false || true

              # Remaining auto-update chain (system domain; no native option).
              for key in AutomaticCheckEnabled AutomaticDownload CriticalUpdateInstall ConfigDataInstall; do
                defaults write /Library/Preferences/com.apple.SoftwareUpdate "$key" -int 1 || true
              done
              defaults write /Library/Preferences/com.apple.SoftwareUpdate ScheduleFrequency -int 1 || true
              defaults write /Library/Preferences/com.apple.commerce AutoUpdate -int 1 || true

              # Ensure automatic login stays off (FileVault already enforces this).
              defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null || true
              rm -f /etc/kcpassword || true

              # Require an admin password to change system-wide settings. Re-applied
              # each rebuild so a macOS upgrade that resets it self-heals.
              if security authorizationdb read system.preferences > /tmp/hardening-sysprefs.plist 2>/dev/null; then
                /usr/libexec/PlistBuddy -c "Set :shared false" /tmp/hardening-sysprefs.plist 2>/dev/null || true
                security authorizationdb write system.preferences < /tmp/hardening-sysprefs.plist 2>/dev/null || true
                rm -f /tmp/hardening-sysprefs.plist || true
              fi

              # Primary-user (per-host / per-user) defaults.
              ${asUser "defaults -currentHost write com.apple.controlcenter AirplayReceiverEnabled -bool false"}
              ${asUser ''defaults write com.apple.assistant.support "Siri Data Sharing Opt-In Status" -int 2''}
              ${asUser "defaults write com.apple.amp.mediasharingd home-sharing-enabled -int 0"}
              ${asUser ''security set-keychain-settings -l "/Users/${primaryUser}/Library/Keychains/login.keychain-db"''}
            '';
          };
      };
    };
}
