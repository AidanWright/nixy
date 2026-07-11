# modules/nix/overlays/darwin-apps.nix
################################################################################
# Exposes prebuilt macOS .app bundles as pkgs.darwinApps.* via the nixy-apps
# flake, which packages them and tracks upstream versions automatically. Tracks
# the `latest` release tag (CalVer), which advances only on real app-version
# releases; `nix flake update nixy-apps` pulls the newest released set.
################################################################################
{ inputs, ... }:
{
  # No nixpkgs.follows: nixy-apps builds xray-builder against its own pinned
  # nixpkgs, which its binary cache is keyed to. Following the project nixpkgs
  # would change the derivation and miss the cache. nix-auto-follow ignores it
  # for the same reason.
  flake-file.inputs.nixy-apps.url = "github:AidanWright/nixy-apps/latest";

  flake.aspects.overlays.darwin-apps.darwin = _: {
    nixpkgs.overlays = [ inputs.nixy-apps.overlays.default ];
  };
}
