# modules/system/minimal/nixos/base.nix
################################################################################
#
################################################################################
{ ... }:
{
  flake.modules.nixos.nixos-minimal =
    { pkgs, ... }:
    {
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

      environment.systemPackages = [ pkgs.git ];
    };
}
