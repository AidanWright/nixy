# modules/nix/flake-parts/_aspects/flake-module.nix
################################################################################
# Flake-parts entry point for the aspect system. Declares the flake.aspects
# input — an arbitrarily nested tree of namespaces and aspects, each aspect
# defining per-class (darwin/nixos/…) config — and computes flake.modules.<class>
# from it, which hosts consume as inputs.self.modules.<class>.<namespace…>.<aspect>.
################################################################################
{ lib, config, ... }:
let
  builtModules = import ./build-modules.nix lib config.flake.aspects;
in
{
  options.flake.aspects = lib.mkOption {
    default = { };
    description = "Aspect tree: flake.aspects.<namespace…>.<aspect>.<class>.";
    type = (import ./aspect-type.nix lib).aspectsType { };
  };

  config.flake.modules = builtModules;

  # The `aspects` fixpoint handed to every `flake.aspects = { aspects, … }:`
  # definition. Each namespace's `all` delegates to the already-built
  # flake.modules entry (a single source of truth that resolves correctly),
  # rather than re-resolving inside the fixpoint.
  config.flake.aspects._module.args.aspects =
    (import ./aggregate-all.nix lib).augmentFixpoint builtModules config.flake.aspects;
}
