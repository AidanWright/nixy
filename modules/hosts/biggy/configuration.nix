# modules/hosts/biggy/configuration.nix
################################################################################
#
################################################################################
{ inputs, ... }:
{
  flake.aspects =
    { aspects, ... }:
    {
      biggy = {
        includes = with aspects; [
          minimal.server
          services.all
          users.aidanwright
        ];

        nixos =
          { ... }:
          {
            networking.hostName = "biggy";

            boot.loader.grub = {
              enable = true;
              efiSupport = true;
              device = "nodev";
            };
            boot.loader.efi.canTouchEfiVariables = true;

            imports = [ inputs.disko.nixosModules.disko ];

            disko.devices.disk.main = {
              #device = "/dev/vda";
              device = "/dev/sda";
              type = "disk";
              content = {
                type = "gpt";
                partitions = {
                  ESP = {
                    size = "512M";
                    type = "EF00";
                    content = {
                      type = "filesystem";
                      format = "vfat";
                      mountpoint = "/boot";
                      mountOptions = [
                        "nodev"
                        "nosuid"
                        "noexec"
                      ];
                    };
                  };
                  root = {
                    size = "100%";
                    content = {
                      type = "btrfs";
                      subvolumes = {
                        "/nix" = {
                          mountpoint = "/nix";
                          mountOptions = [
                            "compress=zstd"
                            "noatime"
                          ];
                        };
                        "/persist" = {
                          mountpoint = "/persist";
                          mountOptions = [
                            "compress=zstd"
                            "noatime"
                            "nodev"
                            "nosuid"
                          ];
                        };
                      };
                    };
                  };
                };
              };
            };

          };
      };
    };
}
