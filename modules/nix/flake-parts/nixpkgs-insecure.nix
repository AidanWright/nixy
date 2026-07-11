# modules/nix/flake-parts/nixpkgs-insecure.nix
################################################################################
# `permittedInsecurePackages` as a concatenating list option, funneled into
# nixpkgs.config as one definition. nixpkgs.config merges via recursiveUpdate,
# which overwrites the list rather than concatenating, so setting it in two
# modules clobbers. Under `basic`, so `basic.all` hosts get it automatically.
################################################################################
{ ... }:
let
  aggregator =
    {
      lib,
      config,
      ...
    }:
    {
      options.permittedInsecurePackages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Package names to allow despite being marked insecure.";
      };

      config.nixpkgs.config.permittedInsecurePackages = config.permittedInsecurePackages;
    };
in
{
  flake.aspects.basic.permittedInsecure.darwin = aggregator;
  flake.aspects.basic.permittedInsecure.nixos = aggregator;
}
