# modules/nix/overlays/nixpkg-unstable.nix
################################################################################
# creates overlay allows us to use pkgs.unstable.<pkg>
# overlay still needs to be consumed to be accessible in system configurations
# we do that in the flake-parts helper lib modules/nix/flake-parts/lib.nix
################################################################################
{ inputs, ... }:
let
  unstableOverlay = final: _: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final.stdenv.hostPlatform) system;
      config = final.config // {
        allowUnfree = true;
      };
    };
  };
in
{
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ unstableOverlay ];
        config = { };
      };
    };

  flake.modules.darwin.unstable-overlay = _: {
    nixpkgs.overlays = [ unstableOverlay ];
  };

  flake.modules.nixos.unstable-overlay = _: {
    nixpkgs.overlays = [ unstableOverlay ];
  };
}
