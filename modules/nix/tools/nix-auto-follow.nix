# modules/nix/tools/nix-auto-follow.nix
################################################################################
# Flattens flake.lock by collapsing duplicate inputs onto the root pins.
# Uses a fork that adds `--ignore`, so nix-nvim keeps its own FlakeHub pins.
################################################################################
{ inputs, lib, ... }:
{
  imports = [ inputs.flake-file.flakeModules.nix-auto-follow ];

  flake-file.inputs.nix-auto-follow.url = lib.mkForce "github:AidanWright/nix-auto-follow/feat/ignore-inputs";

  # nix-nvim ships its own FlakeHub-locked nixpkgs; collapsing it onto the
  # project nixpkgs makes nix re-expand it and breaks check-flake-file. Leave
  # its whole subtree alone instead of pinning every input by hand.
  flake-file.prune-lock.program = lib.mkForce (
    pkgs:
    pkgs.writeShellApplication {
      name = "nix-auto-follow";
      runtimeInputs = [
        inputs.nix-auto-follow.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
      text = ''
        auto-follow --ignore nix-nvim "$1" > "$2"
      '';
    }
  );
}
