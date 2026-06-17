# modules/system/minimal/nixos/base.nix
################################################################################
#
################################################################################
{ inputs, ... }:
{
  flake.modules.nixos.nixos-minimal =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        cli-tools
        sops
      ];

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };

      system.autoUpgrade = {
        enable = true;
        flake = "github:AidanWright/nixy";
        dates = "daily";
      };

      system.stateVersion = "26.05";
    };
}
