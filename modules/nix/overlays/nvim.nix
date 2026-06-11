# modules/nix/overlays/nvim.nix
################################################################################
# Exposes pkgs.nvim-pkg and pkgs.nvim-* from the nix-nvim flake.
################################################################################
{ inputs, ... }:
{
  flake-file.inputs = {
    nix-nvim-nixpkgs.url = "github:NixOS/nixpkgs/c5296fdd05cfa2c187990dd909864da9658df755";
    nix-nvim-gen-luarc-nixpkgs.url = "github:NixOS/nixpkgs/c00d587b1a1afbf200b1d8f0b0e4ba9deb1c7f0e";
    nix-nvim-gen-luarc-flake-parts.url = "github:hercules-ci/flake-parts/2a55567fcf15b1b1c7ed712a2c6fadaec7412ea8";
    nix-nvim-gen-luarc-nixpkgs-lib.url = "https://github.com/NixOS/nixpkgs/archive/eb9ceca17df2ea50a250b6b27f7bf6ab0186f198.tar.gz";
    nix-nvim = {
      url = "https://flakehub.com/f/AidanWright/nix-nvim/*";
      inputs = {
        nixpkgs.follows = "nix-nvim-nixpkgs";
        gen-luarc.inputs = {
          nixpkgs.follows = "nix-nvim-gen-luarc-nixpkgs";
          flake-parts = {
            follows = "nix-nvim-gen-luarc-flake-parts";
            inputs.nixpkgs-lib.follows = "nix-nvim-gen-luarc-nixpkgs-lib";
          };
        };
      };
    };
  };

  flake.modules.darwin.nix-nvim-overlay = _: {
    nixpkgs.overlays = [ inputs.nix-nvim.overlays.default ];
  };

  flake.modules.nixos.nix-nvim-overlay = _: {
    nixpkgs.overlays = [ inputs.nix-nvim.overlays.default ];
  };
}
