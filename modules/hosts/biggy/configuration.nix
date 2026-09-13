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
        includes =
          with aspects;
          with services;
          [
            minimal.server
            minecraft
            aidanwright
            aspects.security.luks
          ];

        nixos =
          { ... }:
          {
            networking.hostName = "biggy";

            # Initrd needs the NIC up before the disk is unlocked, for both the
            # Tang fetch and the SSH fallback.
            boot.initrd.availableKernelModules = [
              "virtio_net"
              "virtio_pci"
            ];

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
                      type = "luks";
                      name = "cryptroot";
                      passwordFile = "/tmp/luks.key";
                      settings.allowDiscards = true;
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
    };
}
