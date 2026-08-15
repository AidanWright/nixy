# modules/services/web/latex/syncthing.nix
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
  flake.aspects.services.web.latex.syncthing = {
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

          # Syncthing runs as the login user aidanwright rather than a system
          # user, so without a profile it inherits that user's full reach over
          # the filesystem. This confines it to the folders it actually syncs.
          (inputs.self.lib.mkServiceProfile {
            name = "syncthing";
            packages = { config, ... }: [ config.services.syncthing.package ];
            rules =
              { config, ... }:
              ''
                ${config.services.syncthing.configDir}/ r,
                ${config.services.syncthing.configDir}/** rwkl,
                ${config.services.syncthing.dataDir}/ r,
                ${config.services.syncthing.dataDir}/** rwkl,

                # The one shared folder. Deliberately not @{HOME}: syncthing has
                # no reason to reach the rest of aidanwright's home directory.
                /srv/latex/ r,
                /srv/latex/** rwkl,

                owner @{PROC}/@{pid}/** r,
              '';
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
