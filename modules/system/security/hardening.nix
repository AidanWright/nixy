# modules/system/security/hardening.nix
################################################################################
# Follow some common sense system security settings.
################################################################################
{ ... }:
{
  flake.aspects =
    { aspects, ... }:
    {
      security.hardening = {
        # darwin.siri.* options come from the options.base aspect
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
            # https://github.com/ernw/hardening/blob/master/operating_system/osx/26/Hardening_Guide-macOS_26_Tahoe_1.0.md#enable-macos-firewall
            networking.applicationFirewall = {
              enable = true;
              # Prevent the system from responding to uninvited probing requests (e.g., ICMP Echo).
              # However, the computer still answers incoming requests for authorized apps. Unexpected requests are ignored.
              enableStealthMode = true;

              # Built-in software not automatically allowed to receive incoming connections
              allowSigned = false;
              # Downloaded signed software software not automatically allowed to receive incoming connections
              allowSignedApp = false;

              # WARNING: prevents all sharing services, such as File Sharing and Screen Sharing, from receiving incoming connections.
              #
              # blockAllIncoming = true;
            };

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

              # https://github.com/ernw/hardening/blob/master/operating_system/osx/26/Hardening_Guide-macOS_26_Tahoe_1.0.md#ensure-system-integrity-protection-is-enabled
              if ! csrutil status | /usr/bin/grep -q 'enabled'; then
                echo "ERR: System Integrity Protection disabled."
                echo "Recommended to erase the Mac and reinstall the operating system."
              fi

              # https://github.com/ernw/hardening/blob/master/operating_system/osx/26/Hardening_Guide-macOS_26_Tahoe_1.0.md#ensure-system-volume-is-read-only
              if ! system_profiler SPStorageDataType | awk '/Mount Point: \/$/{x=NR+2}(NR==x)' | /usr/bin/grep -q 'No'; then
                echo "ERR: System volume mounted as writable"
                echo "Rebooting the computer will mount the system volume as read-only."
              fi

              # https://github.com/ernw/hardening/blob/master/operating_system/osx/26/Hardening_Guide-macOS_26_Tahoe_1.0.md#enable-authenticated-root
              if ! csrutil authenticated-root status | /usr/bin/grep -q 'enabled'; then
                echo "ERR: Authenticated root disabled"
                echo "boot the system into Recovery mode and run 'csrutil authenticated-root enable'"
              fi

              # https://github.com/ernw/hardening/blob/master/operating_system/osx/26/Hardening_Guide-macOS_26_Tahoe_1.0.md#gatekeeper
              if spctl --status --verbose | /usr/bin/grep -q 'disabled'; then
                echo "ERR: Gatekeeper disabled for one or both of: assessments, developer id"
                echo "Attempting to enable..."
                /usr/sbin/spctl --global-enable 
              fi

              # https://github.com/ernw/hardening/blob/master/operating_system/osx/26/Hardening_Guide-macOS_26_Tahoe_1.0.md#filevault
              if ! fdesetup status -extended | /usr/bin/grep -q 'On'; then
                echo "ERR: Filevault is disabled"
                echo "Attempting to enable... User input required"
                /usr/bin/fdesetup enable
              fi

              # https://github.com/ernw/hardening/blob/master/operating_system/osx/26/Hardening_Guide-macOS_26_Tahoe_1.0.md#restrict-users
              echo "The following users are authorized to unlock FileVault (should be at least one):"
              /usr/bin/fdesetup list | awk -F ',' '{print $1}'

              # https://github.com/ernw/hardening/blob/master/operating_system/osx/26/Hardening_Guide-macOS_26_Tahoe_1.0.md#disable-system-diagnostic-and-usage-data-reporting
              defaults write com.apple.CrashReporter DialogType none 
              defaults write com.apple.CrashReporter DialogType crashreport

              # https://github.com/ernw/hardening/blob/master/operating_system/osx/26/Hardening_Guide-macOS_26_Tahoe_1.0.md#volume-ownership-secure-token
              # if ! sudo sysadminctl -secureTokenStatus "$(id -un)" | /usr/bin/grep -q 'ENABLED'; then
              #   echo "ERR: Secure Token disabled for current user"
              # fi

              # https://github.com/ernw/hardening/blob/master/operating_system/osx/26/Hardening_Guide-macOS_26_Tahoe_1.0.md#disable-automatic-login-and-user-list 
              defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null || true
              rm -f /etc/kcpassword || true

              # https://github.com/ernw/hardening/blob/master/operating_system/osx/26/Hardening_Guide-macOS_26_Tahoe_1.0.md#disable-creation-of-metadata-files
              defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true || true
              defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true || true

              # https://github.com/ernw/hardening/blob/master/operating_system/osx/26/Hardening_Guide-macOS_26_Tahoe_1.0.md#disable-network-services--sharing
              ${lib.concatMapStringsSep "\n              " (
                service: "launchctl disable system/${service} || true"
              ) disabledServices}
              /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -deactivate -stop || true
              /usr/bin/AssetCacheManagerUtil deactivate || true
              /usr/sbin/cupsctl --no-share-printers || true

              # https://github.com/ernw/hardening/blob/master/operating_system/osx/26/Hardening_Guide-macOS_26_Tahoe_1.0.md#disable-power-nap-and-network-wake
              /usr/bin/pmset -a womp 0 || true

              # Touch ID: fall back to the password after 30 min (default is 2 days).
              /usr/bin/bioutil -w -s --btimeout 1800 || true

              # auto-update chain
              for key in AutomaticCheckEnabled AutomaticDownload CriticalUpdateInstall ConfigDataInstall; do
                defaults write /Library/Preferences/com.apple.SoftwareUpdate "$key" -int 1 || true
              done
              defaults write /Library/Preferences/com.apple.SoftwareUpdate ScheduleFrequency -int 1 || true
              defaults write /Library/Preferences/com.apple.commerce AutoUpdate -int 1 || true

              # Require an admin password to change system-wide settings
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
