# modules/nix/flake-parts/_aspects/flake-module.nix
################################################################################
# Flake-parts entry point for the aspect system. Declares the flake.aspects
# input — an arbitrarily nested tree of namespaces and aspects, each aspect
# defining per-class (darwin/nixos/…) config — and computes flake.modules.<class>
# from it, which hosts consume as inputs.self.modules.<class>.<namespace…>.<aspect>.
################################################################################
{ lib, config, ... }:
{
  options.flake.aspects = lib.mkOption {
    default = { };
    description = "Aspect tree: flake.aspects.<namespace…>.<aspect>.<class>.";
    type = (import ./aspect-type.nix lib).aspectsType { };
  };

  config.flake.modules = import ./build-modules.nix lib config.flake.aspects;
}
