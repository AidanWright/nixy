# modules/programs/vscode.nix
################################################################################
#  Visual Studio Code
################################################################################
{ ... }:
{
  flake.aspects.programs.vscode.homeManager =
    { lib, pkgs, ... }:
    {
      programs.vscode = {
        enable = true;
        package = lib.mkForce pkgs.master.vscode;
      };
    };
}
