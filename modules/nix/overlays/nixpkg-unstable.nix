# modules/nix/overlays/nixpkg-unstable.nix
################################################################################
# Creates an overlay that exposes pkgs.unstable.<pkg> across all configurations.
# The overlay must be applied in each host's module list to take effect.
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

  flake.aspects.overlays.unstable.darwin = _: {
    nixpkgs.overlays = [ unstableOverlay ];
  };

  flake.aspects.overlays.unstable.nixos = _: {
    nixpkgs.overlays = [ unstableOverlay ];
  };
}
