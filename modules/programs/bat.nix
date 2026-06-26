# modules/programs/bat.nix
################################################################################
# bat plus the bat-extras commands (batdiff/batgrep/batman/batwatch/prettybat),
# with cat/grep/man/diff/watch aliased to their bat equivalents in fish.
################################################################################
{ ... }:
{
  flake.aspects.programs.bat.homeManager =
    { pkgs, ... }:
    {
      programs.bat = {
        enable = true;
        extraPackages = with pkgs.bat-extras; [
          batdiff
          batgrep
          batman
          batwatch
          prettybat
        ];
      };

      # Route the everyday commands through their bat-extras equivalents. These
      # are fish aliases, so POSIX (`#!/bin/sh`) scripts keep the originals.
      programs.fish.shellAliases = {
        cat = "bat";
        grep = "batgrep";
        man = "batman";
        diff = "batdiff";
        watch = "batwatch";
      };
    };
}
