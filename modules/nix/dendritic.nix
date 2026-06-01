# modules/nix/dendritic.nix
################################################################################
# Set's up the basic project ecosystem using some of vic's libraries.
# Because we use flake-file, we can use imports close to the code, not just here
################################################################################
{ inputs, lib, ... }:
{
  imports = [
    # See more: https://github.com/denful/flake-file/tree/main/modules/dendritic
    inputs.flake-file.flakeModules.dendritic
    # See more: https://flake-file.denful.dev/guides/lock-flattening/
    inputs.flake-file.flakeModules.nix-auto-follow
  ];

  flake-file.inputs = {
    # Currently, we build everything against stable and only Selectively pick
    # packages from unstable.
    nixpkgs.url = lib.mkForce "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = lib.mkDefault "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      # Version must match version of nixpkgs. i.e. if nixpkgs 25.11 then nix-darwin 25.11
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/0.2605.2360";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  flake-file.description = "Base configurations for my NixOs Desktop & Servers and Nix-Darwin hosts";
  flake-file.style.sep.inputs = "\n\n";
}
