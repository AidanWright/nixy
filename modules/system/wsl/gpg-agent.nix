# modules/system/wsl/gpg-agent.nix
################################################################################
# WSL-only: signs with a YubiKey on the Windows host. WSL2 can't reach smart
# cards, so socat relays gpg's agent socket to the Windows (Gpg4win) agent via
# wsl2-ssh-pageant.exe. Import your public key once: `gpg --import`.
#
# Deliberately outside the `programs` namespace: hosts include `programs.all`,
# and a `.all` aggregate sweeps in every descendant regardless of platform.
################################################################################
{ ... }:
{
  flake.aspects.wsl.gpg-agent.homeManager =
    { pkgs, ... }:
    let
      relayBin = pkgs.fetchurl {
        url = "https://github.com/BlackReloaded/wsl2-ssh-pageant/releases/download/v1.4.0/wsl2-ssh-pageant.exe";
        hash = "sha256-HQXdpg9uNmFKS7THuUnh9alNh6nmrQI+v017y9KVJY4=";
        executable = true;
      };

      relayLauncher = pkgs.writeShellScript "gpg-agent-relay-exec" ''
        exec ${relayBin} --gpgConfigBasepath "$GPG_WINDOWS_HOME" --gpg S.gpg-agent
      '';

      # The colon-bearing Windows path goes out-of-band so socat's address
      # parser doesn't split it; the path itself is per-machine, so resolve it
      # at runtime rather than baking in a user.
      relayScript = pkgs.writeShellScript "gpg-agent-relay" ''
        set -eu
        cmd="$(command -v cmd.exe || echo /mnt/c/Windows/System32/cmd.exe)"
        localAppData="$("$cmd" /d /c 'echo %LOCALAPPDATA%' 2>/dev/null | ${pkgs.coreutils}/bin/tr -d '\r\n')"
        export GPG_WINDOWS_HOME="''${localAppData}\\gnupg"
        exec ${pkgs.socat}/bin/socat \
          UNIX-LISTEN:"$XDG_RUNTIME_DIR/gnupg/S.gpg-agent",fork \
          EXEC:${relayLauncher}
      '';
    in
    {
      # The relay shells out to cmd.exe, so the aspect is meaningless anywhere
      # a Windows host is not underneath it.
      assertions = [
        {
          assertion = pkgs.stdenv.hostPlatform.isLinux;
          message = "wsl.gpg-agent requires a Linux host running under WSL.";
        }
      ];

      services.gpg-agent.enable = false;

      systemd.user.services.gpg-agent-relay = {
        Unit.Description = "Relay gpg's agent socket to the Windows gpg-agent";
        Service = {
          Type = "simple";
          # %t is $XDG_RUNTIME_DIR; 0700 or gpg warns about the socket dir.
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
