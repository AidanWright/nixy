# modules/nix/overlays/darwin-apps.nix
################################################################################
# Exposes prebuilt macOS .app bundles as pkgs.darwinApps.* via the nixy-apps
# flake, which packages them and tracks upstream versions automatically. To bump
# a version, update apps.json in github:AidanWright/nixy-apps (CI does this
# hourly); here just `nix flake update nixy-apps`.
################################################################################
{ inputs, ... }:
{
  flake-file.inputs.nixy-apps = {
    url = "github:AidanWright/nixy-apps";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.aspects.overlays.darwin-apps.darwin = _: {
    nixpkgs.overlays = [ inputs.nixy-apps.overlays.default ];
  };
}
