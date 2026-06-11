# flake.nix
################################################################################
# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
################################################################################

{
  description = "Base configurations for my NixOs Desktop & Servers and Nix-Darwin hosts";

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  inputs = {
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
      inputs = {
        nix.inputs = {
          flake-parts.follows = "flake-parts";
          nixpkgs.follows = "determinate/nixpkgs";
        };
        nixpkgs.follows = "nixpkgs";
      };
    };

    flake-file.url = "github:vic/flake-file";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    homebrew-bengerthelorf = {
      url = "github:Bengerthelorf/homebrew-tap";
      flake = false;
    };

    homebrew-zoho = {
      url = "github:AidanWright/homebrew-zoho";
      flake = false;
    };

    import-tree.url = "github:vic/import-tree";

    nix-auto-follow = {
      url = "github:fzakaria/nix-auto-follow";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    nix-nvim = {
      url = "https://flakehub.com/f/AidanWright/nix-nvim/*";
      inputs = {
        gen-luarc.inputs = {
          flake-parts = {
            follows = "nix-nvim-gen-luarc-flake-parts";
            inputs.nixpkgs-lib.follows = "nix-nvim-gen-luarc-nixpkgs-lib";
          };
          nixpkgs.follows = "nix-nvim-gen-luarc-nixpkgs";
        };
        nixpkgs.follows = "nix-nvim-nixpkgs";
      };
    };

    nix-nvim-gen-luarc-flake-parts.url = "github:hercules-ci/flake-parts/2a55567fcf15b1b1c7ed712a2c6fadaec7412ea8";

    nix-nvim-gen-luarc-nixpkgs.url = "github:NixOS/nixpkgs/c00d587b1a1afbf200b1d8f0b0e4ba9deb1c7f0e";

    nix-nvim-gen-luarc-nixpkgs-lib.url = "https://github.com/NixOS/nixpkgs/archive/eb9ceca17df2ea50a250b6b27f7bf6ab0186f198.tar.gz";

    nix-nvim-nixpkgs.url = "github:NixOS/nixpkgs/c5296fdd05cfa2c187990dd909864da9658df755";

    nixos-shell = {
      url = "github:Mic92/nixos-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        systems.follows = "systems";
      };
    };

    stylix = {
      url = "github:danth/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    systems.url = "github:nix-systems/default";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
