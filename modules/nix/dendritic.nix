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
    inputs.flake-aspects.flakeModule
  ];

  flake-file.inputs = {
    # mkForce locks stable so no transitive input can silently upgrade nixpkgs.
    nixpkgs.url = lib.mkForce "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = lib.mkDefault "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-aspects.url = "github:denful/flake-aspects";
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
