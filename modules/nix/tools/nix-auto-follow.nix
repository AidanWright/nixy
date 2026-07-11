# modules/nix/tools/nix-auto-follow.nix
################################################################################
# Flattens flake.lock by collapsing duplicate inputs onto the root pins.
################################################################################
{ inputs, lib, ... }:
{
  imports = [ inputs.flake-file.flakeModules.nix-auto-follow ];

  flake-file.inputs.nix-auto-follow.url = lib.mkForce "github:fzakaria/nix-auto-follow";

  # nix-nvim ships its own FlakeHub-locked nixpkgs; collapsing it onto the
  # project nixpkgs makes nix re-expand it and breaks check-flake-file. Leave
  # its whole subtree alone instead of pinning every input by hand.
  #
  # nixy-apps' binary cache is keyed to its own pinned nixpkgs; collapsing it
  # onto the project nixpkgs changes the buildDotnetModule toolchain and misses
  # the cache, forcing a from-source (relaxed-sandbox) build of xray-builder.
  flake-file.prune-lock.program = lib.mkForce (
    pkgs:
    pkgs.writeShellApplication {
      name = "nix-auto-follow";
      runtimeInputs = [
        inputs.nix-auto-follow.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
      text = ''
        auto-follow --ignore nix-nvim --ignore nixy-apps "$1" > "$2"
      '';
    }
  );
}
