# modules/nix/tools/treefmt.nix
################################################################################
# To format the project use `nix fmt`. Should also enforce linting when running
# `nix flake check`. We can enable other formatters/linters with
# `perSystem.treefmt.programs.<formatter>.enable = true`
# A full list can be found at: github.com/numtide/treefmt-nix/tree/main/programs
################################################################################
{ inputs, ... }:
{
  flake-file.inputs = {
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    systems.url = "github:nix-systems/default";
  };

  flake-file.do-not-edit = "flake.nix
  ################################################################################
  # DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
  # Use `nix run .#write-flake` to regenerate it.
  ################################################################################
  ";

  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { pkgs, ... }:
    let
      headerScript = pkgs.writeShellScript "header" ''
        exec ${pkgs.python3}/bin/python3 ${./header.py} "$@"
      '';
    in
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
        settings.formatter.nixfmt = {
          excludes = [ "flake.lock" ];
          priority = 1;
        };
        settings.formatter.header = {
          command = "${headerScript}";
          includes = [
            "*.nix"
            "*.py"
          ];
          excludes = [
            "flake.lock"
            "flake.nix"
          ];
          priority = 0;
        };
      };
    };
}
