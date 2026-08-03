# modules/programs/cli/gpg-wsl.nix
################################################################################
# Signs commits in WSL with a YubiKey that is plugged into the Windows host.
#
# WSL2 cannot see USB smart cards, so instead of running scdaemon here this
# aspect forwards GnuPG's agent socket to the Windows (Gpg4win) gpg-agent, which
# owns the card. A `socat` listener replaces the socket `gpgconf` expects under
# $XDG_RUNTIME_DIR and relays each connection through `wsl2-ssh-pageant.exe`
# (run via WSL's Windows-interop), so `gpg`/`git` in WSL sign transparently and
# the PIN/touch prompt appears on Windows.
#
# Gpg4win 5 keeps GnuPG's home under the Windows %LOCALAPPDATA%\gnupg (older
# GnuPG used %APPDATA%\gnupg, which is all the relay knows). The wrapper resolves
# the real path at runtime — no hard-coded Windows user — and passes it via the
# relay's --gpgConfigBasepath.
#
# Prerequisites on the Windows side (one-time):
#   1. Install Gpg4win and confirm `gpg --card-status` sees the YubiKey.
#   2. Make sure its gpg-agent is running (Kleopatra, or a login task running
#      `gpg-connect-agent /bye`) so it creates <home>\gnupg\S.gpg-agent.
#
# Layer this aspect only onto the standalone WSL home (see the home's module
# list); it overrides the local agent from `programs.gpg`.
################################################################################
{ ... }:
{
  flake.aspects.programs.gpg-wsl.homeManager =
    { pkgs, ... }:
    let
      # v1.4.0 ships a single Windows binary; wrapped only to gain the execute
      # bit (fetchurl store paths are 0444, which execve/interop rejects).
      wsl2-ssh-pageant = pkgs.runCommandLocal "wsl2-ssh-pageant.exe" { } ''
        install -Dm755 ${
          pkgs.fetchurl {
            url = "https://github.com/BlackReloaded/wsl2-ssh-pageant/releases/download/v1.4.0/wsl2-ssh-pageant.exe";
            hash = "sha256-b3FFf4PTwY9ekGE7tMui5QGIW4EkCcTC+GwC1dxDez0=";
          }
        } $out/bin/wsl2-ssh-pageant.exe
      '';
      relayBin = "${wsl2-ssh-pageant}/bin/wsl2-ssh-pageant.exe";

      # socat runs this per connection. The Windows base path carries its own
      # colon-and-backslash drive spec, which socat's address parser would
      # mangle, so it arrives out-of-band in the environment instead.
      relayLauncher = pkgs.writeShellScript "gpg-agent-relay-exec" ''
        exec ${relayBin} --gpgConfigBasepath "$GPG_WINDOWS_HOME" --gpg S.gpg-agent
      '';

      # The Windows home is only known at runtime (per-machine user), so resolve
      # it here rather than baking it into the unit.
      relayScript = pkgs.writeShellScript "gpg-agent-relay" ''
        set -eu
        # systemd user services carry no Windows PATH; reach cmd.exe directly.
        cmd="$(command -v cmd.exe || echo /mnt/c/Windows/System32/cmd.exe)"
        localAppData="$("$cmd" /d /c 'echo %LOCALAPPDATA%' 2>/dev/null | ${pkgs.coreutils}/bin/tr -d '\r\n')"
        export GPG_WINDOWS_HOME="''${localAppData}\\gnupg"
        exec ${pkgs.socat}/bin/socat \
          UNIX-LISTEN:"$XDG_RUNTIME_DIR/gnupg/S.gpg-agent",fork \
          EXEC:${relayLauncher}
      '';
    in
    {
      # gpg needs the public key locally to derive the keygrip it asks the
      # (Windows) agent to sign with; the private half never leaves the card.
      # The card is not reachable here to import it, so ship the exported key.
      programs.gpg.publicKeys = [
        {
          source = ./gpg-wsl-signing-key.pub.asc;
          trust = "ultimate";
        }
      ];

      # This box signs with the ed25519 key generated on its YubiKey, not the
      # shared default (which is a different card on the Mac).
      programs.git.signing.key = "73663FC16A19BD82";

      # The local agent would grab the same socket the relay needs.
      services.gpg-agent.enable = false;

      home.packages = [ pkgs.socat ];

      systemd.user.services.gpg-agent-relay = {
        Unit = {
          Description = "Bridge GnuPG's agent socket to the Windows (Gpg4win) gpg-agent";
          Documentation = [ "https://github.com/BlackReloaded/wsl2-ssh-pageant" ];
        };
        Service = {
          Type = "simple";
          # %t is $XDG_RUNTIME_DIR (/run/user/$UID) — where `gpgconf` reports the
          # agent socket. Recreate the dir at 0700 so gpg does not warn, and drop
          # any stale socket before listening.
          ExecStartPre = [
            "${pkgs.coreutils}/bin/install -d -m 0700 %t/gnupg"
            "-${pkgs.coreutils}/bin/rm -f %t/gnupg/S.gpg-agent"
          ];
          ExecStart = relayScript;
          Restart = "on-failure";
          RestartSec = 2;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
