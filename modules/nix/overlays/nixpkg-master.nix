# modules/nix/overlays/nixpkg-master.nix
################################################################################
# Creates an overlay that exposes pkgs.master.<pkg> from the nixpkgs master
# branch. The overlay must be applied in each host's module list to take effect.
################################################################################
{ inputs, ... }:
let
  masterOverlay = final: _: {
    master = import inputs.nixpkgs-master {
      inherit (final.stdenv.hostPlatform) system;
      config = final.config // {
        allowUnfree = true;
      };
    };
  };
in
{
  flake-file.inputs.nixpkgs-master.url = "github:NixOS/nixpkgs/master";

  flake.aspects.master-overlay.darwin = _: {
    nixpkgs.overlays = [ masterOverlay ];
  };

  flake.aspects.master-overlay.nixos = _: {
    nixpkgs.overlays = [ masterOverlay ];
  };
}
