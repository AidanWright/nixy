# modules/nix/overlays/vscode-extensions.nix
################################################################################
# https://github.com/nix-community/nix-vscode-extensions
# Adds the nix-vscode-extensions overlay so hosts can reference VS Code and
# Open VSX extensions as `pkgs.nix-vscode-extensions.{open-vsx,vscode-marketplace}.*`.
################################################################################
{ inputs, ... }:
{
  flake-file.inputs.nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";

  flake.aspects.overlays.vscode-extensions.nixos = _: {
    nixpkgs.overlays = [ inputs.nix-vscode-extensions.overlays.default ];
  };
}
