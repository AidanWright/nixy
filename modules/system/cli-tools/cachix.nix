# modules/system/cli-tools/cachix.nix
################################################################################
# Configures additional binary caches.
################################################################################
{ ... }:
{
  flake.modules.darwin.cachix =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      caches = {
        extra-substituters = [
          "https://aidanwright.cachix.org"
          "https://nix-community.cachix.org"
        ];
        extra-trusted-public-keys = [
          "aidanwright.cachix.org-1:0SQiDDByZEpl3h36s1ItafKKMAcOoAlN3X9tApoDRog="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
    in
    lib.mkMerge [
      { environment.systemPackages = [ pkgs.cachix ]; }
      (lib.mkIf config.determinateNix.enable { determinateNix.customSettings = caches; })
      (lib.mkIf (!config.determinateNix.enable) { nix.settings = caches; })
    ];

  flake.modules.nixos.cachix =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.cachix ];
      nix.settings = {
        extra-substituters = [
          "https://aidanwright.cachix.org"
          "https://nix-community.cachix.org"
        ];
        extra-trusted-public-keys = [
          "aidanwright.cachix.org-1:0SQiDDByZEpl3h36s1ItafKKMAcOoAlN3X9tApoDRog="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
    };
}
