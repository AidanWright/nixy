# modules/nix/overlays/vscode-extensions.nix
################################################################################
# https://github.com/nix-community/nix-vscode-extensions
# Exposes extensions as `pkgs.nix-vscode-extensions.{open-vsx,vscode-marketplace}.*`.
################################################################################
{ inputs, ... }:
let
  vscodeExtensionsOverlay = inputs.nix-vscode-extensions.overlays.default;
in
{
  flake-file.inputs.nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";

  flake.aspects.overlays.vscode-extensions.nixos = _: {
    nixpkgs.overlays = [ vscodeExtensionsOverlay ];
  };

  flake.aspects.overlays.vscode-extensions.darwin = _: {
    nixpkgs.overlays = [ vscodeExtensionsOverlay ];
  };
}
