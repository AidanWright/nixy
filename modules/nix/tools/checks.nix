# modules/nix/tools/checks.nix
################################################################################
# Exposes every host configuration as a flake check, so `nix flake check` builds
# what CI builds and CI needs no build commands of its own.
#
# Check all outputs for the current system: nix flake check
# Build one host: nix build .#checks.<system>.nixos-<host>
################################################################################
{ lib, config, ... }:
{
  perSystem =
    { system, ... }:
    let
      # Each configuration only builds on the platform it targets, so they are
      # filtered per system rather than being exposed everywhere and failing.
      forSystem =
        configurations: lib.filterAttrs (_: c: c.pkgs.stdenv.hostPlatform.system == system) configurations;

      checksFrom =
        prefix: toplevel: configurations:
        lib.mapAttrs' (name: c: lib.nameValuePair "${prefix}-${name}" (toplevel c)) (
          forSystem configurations
        );
    in
    {
      checks =
        checksFrom "nixos" (c: c.config.system.build.toplevel) config.flake.nixosConfigurations
        // checksFrom "darwin" (c: c.config.system.build.toplevel) config.flake.darwinConfigurations
        // checksFrom "home" (c: c.activationPackage) config.flake.homeConfigurations;
    };
}
