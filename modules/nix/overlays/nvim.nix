# modules/nix/overlays/nvim.nix
################################################################################
# Exposes pkgs.nvim-pkg and pkgs.nvim-* from the nix-nvim flake.
################################################################################
{ inputs, ... }:
{
  flake-file.inputs.nix-nvim.url = "https://flakehub.com/f/AidanWright/nix-nvim/*";

  flake.aspects.nix-nvim-overlay.darwin = _: {
    nixpkgs.overlays = [ inputs.nix-nvim.overlays.default ];
  };

  flake.aspects.nix-nvim-overlay.nixos = _: {
    nixpkgs.overlays = [ inputs.nix-nvim.overlays.default ];
  };
}
