# modules/services/syncthing.nix
################################################################################
# https://syncthing.net/
# Continuous file sync between biggy and macbook-pro.
#
# NixOS (biggy): runs as a system service owned by aidanwright, GUI bound to
# all interfaces but reachable only over Tailscale (firewall). The `latex`
# folder is declared here; device pairing is a one-time step done through the
# GUI at http://<tailscale-ip>:8384 after first deploy.
#
# Darwin (macbook-pro): installed via the Syncthing Homebrew cask, which
# provides a menubar app and launchd agent. Folder and device pairing are
# configured through the GUI at http://localhost:8384.
################################################################################
{ inputs, ... }:
{
  flake.aspects.services.syncthing = {
    nixos =
      { ... }:
      {
        persistentDirectories = [ "/var/lib/syncthing" ];

        # Device IDs are not hardcoded here — pairing is completed once via the
        # GUI over Tailscale after the first deploy.
        imports = [
          (inputs.self.lib.tailscaleOnlyPorts {
            tcp = [
              8384
              22000
            ];
            udp = [
              22000
              21027
            ];
          })
        ];

        services.syncthing = {
          enable = true;
          user = "aidanwright";
          group = "users";
          openDefaultPorts = false;
          guiAddress = "0.0.0.0:8384";
          overrideDevices = false;
          overrideFolders = false;
          settings.folders.latex.path = "/srv/latex";
        };
      };

    darwin =
      { ... }:
      {
        homebrew.casks = [ "syncthing" ];
      };
  };
}
