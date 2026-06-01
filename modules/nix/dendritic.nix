# modules/nix/dendritic.nix
################################################################################
# Sets up the project ecosystem: flake-file manages inputs, nix-auto-follow
# keeps dependency versions consistent across all inputs automatically.
################################################################################
{ inputs, lib, ... }:
{
  imports = [
    inputs.flake-file.flakeModules.dendritic
    inputs.flake-file.flakeModules.nix-auto-follow
  ];

  flake-file.inputs = {
    # mkForce locks stable so no transitive input can silently upgrade nixpkgs.
    nixpkgs.url = lib.mkForce "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = lib.mkDefault "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      # nix-darwin versioning tracks nixpkgs — nix-darwin-26.05 requires nixos-26.05.
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/0.2605.2360";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  flake-file.description = "Base configurations for my NixOs Desktop & Servers and Nix-Darwin hosts";
  flake-file.style.sep.inputs = "\n\n";
}
