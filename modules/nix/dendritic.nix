# modules/nix/dendritic.nix
################################################################################
# Sets up the project ecosystem: flake-file manages inputs and regenerates
# flake.nix from the module declarations spread across the tree.
################################################################################
{ inputs, lib, ... }:
{
  imports = [
    inputs.flake-file.flakeModules.dendritic
    ./flake-parts/_aspects/flake-module.nix
  ];

  flake-file.inputs = {
    # mkForce locks stable so no transitive input can silently upgrade nixpkgs.
    nixpkgs.url = lib.mkForce "github:NixOS/nixpkgs/nixos-26.05";
  };

  flake-file.description = "Base configurations for my NixOs Desktop & Servers and Nix-Darwin hosts";
  flake-file.style.sep.inputs = "\n\n";

  systems = [
    "aarch64-darwin"
    "aarch64-linux"
    # I personally don't use a intel macbook
    #"x86_64-darwin"
    "x86_64-linux"
  ];
}
