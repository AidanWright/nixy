# modules/system/security/impermanence.nix
################################################################################
# https://github.com/nix-community/impermanence
# Ephemeral tmpfs root: wipes / on every boot and bind-mounts declared paths
# from /persist so only intentional state survives a reboot.
################################################################################
{ inputs, ... }:
{
  flake-file.inputs.impermanence.url = "github:nix-community/impermanence";

  flake.aspects.security.impermanence.nixos =
    {
      config,
      lib,
      ...
    }:
    {
      imports = [ inputs.impermanence.nixosModules.impermanence ];

      # Root is a tmpfs wiped on every boot; this is inherent to the
      # impermanence pattern and belongs here rather than in the host config.
      fileSystems."/" = {
        device = "none";
        fsType = "tmpfs";
        options = [
          "defaults"
          "size=2G"
          "mode=755"
        ];
      };

      # /persist must be available before any service needing its bind-mounts
      # starts; this is inherent to tmpfs-root impermanence.
      fileSystems."/persist".neededForBoot = true;

      environment.persistence."/persist" = {
        hideMounts = true;
        directories = [
          # nixos module allocates stable uids/gids here; without it every
          # rebuild can reassign ownership on /persist and /home.
          "/var/lib/nixos"
          "/var/log"
        ]
        ++ config.persistentDirectories;
        files = [ "/etc/machine-id" ] ++ config.persistentFiles;
      };
    };
}
