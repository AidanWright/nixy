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
      imports = [
        inputs.impermanence.nixosModules.impermanence
        inputs.self.modules.nixos."options.persistence"
      ];

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
          # Holds the timestamps behind timerConfig.Persistent. On a tmpfs root
          # every timer would otherwise believe it had never run and fire on
          # each boot, which is the opposite of a catch-up guarantee.
          "/var/lib/systemd"
        ]
        ++ config.persistentDirectories;
        files = [ "/etc/machine-id" ] ++ config.persistentFiles;
      };

      # Persisted parent directories are created 0755 root:root, but systemd
      # creates this one 0700 and ignores it already existing, so DynamicUser
      # state would stay world-traversable once impermanence has made it.
      systemd.tmpfiles.rules = [ "d /var/lib/private 0700 root root - -" ];
    };
}
