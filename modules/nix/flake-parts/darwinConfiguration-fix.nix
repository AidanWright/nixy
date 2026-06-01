# modules/nix/flake-parts/darwinConfiguration-fix.nix
################################################################################
# Defines flake.darwinConfigurations since nix-darwin has no native flake-parts module.
# https://github.com/Doc-Steve/dendritic-design-with-flake-parts/blob/main/modules/nix/flake-parts%20%5B%5D/darwinConfigurations-fix.nix
################################################################################
{
  lib,
  flake-parts-lib,
  ...
}:
{
  # currently, there's no nix-darwin module for flake-parts,
  # so we have to manually add flake.darwinConfigurations

  options = {
    flake = flake-parts-lib.mkSubmoduleOptions {
      darwinConfigurations = lib.mkOption {
        type = lib.types.lazyAttrsOf lib.types.raw;
        default = { };
      };
    };
  };
}
