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
          services.all
        ];

        nixos =
          { ... }:
          {
            networking.hostName = "biggy"; 

            #imports = [ inputs.disko.nixosModules.disko ];

            #disko.devices.disk.main = {
            #  device = "/dev/vda";
            #  type = "disk";
            #  content = {
            #    type = "gpt";
            #    partitions = {
            #      ESP = {
            #        size = "512M";
            #        type = "EF00";
            #        content = {
            #          type = "filesystem";
            #          format = "vfat";
            #          mountpoint = "/boot";
            #        };
            #      };
            #      root = {
            #        size = "100%";
            #        content = {
            #          type = "filesystem";
            #          format = "ext4";
            #          mountpoint = "/";
            #        };
            #      };
            #    };
            #  };
            #};
          };
      };
    };
}
