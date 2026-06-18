# modules/hosts/biggy/configuration.nix
################################################################################
#
################################################################################
{ inputs, ... }:
{
  flake.aspects.biggy.nixos =
    { ... }:
    {
      imports =
        (with inputs.self.modules.nixos; [
          tailscale
          ssh
          nginx
        ])
        ++ [ inputs.disko.nixosModules.disko ];

      networking.hostName = "biggy";

      sops.secrets.tailscale-auth-key.sopsFile = ./tailscale-auth-key.yaml;

      disko.devices.disk.main = {
        device = "/dev/vda";
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
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
}
