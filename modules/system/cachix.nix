# modules/system/cachix.nix
################################################################################
#
################################################################################
{ ... }:
{
  flake.modules.darwin.cachix =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.cachix ];
      determinateNix.customSettings = {
        extra-substituters = [ "https://aidanwright.cachix.org" "https://nix-community.cachix.org"];
        extra-trusted-public-keys = [ "aidanwright.cachix.org-1:0SQiDDByZEpl3h36s1ItafKKMAcOoAlN3X9tApoDRog=" "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="];
      };
    };
}
