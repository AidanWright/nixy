# modules/programs/zoho.nix
################################################################################
# Adds the homebrew-zoho tap and installs Zoho desktop apps.
################################################################################
{ inputs, ... }:
{
  flake-file.inputs.homebrew-zoho = {
    url = "github:AidanWright/homebrew-zoho";
    flake = false;
  };

  flake.modules.darwin.zoho =
    { ... }:
    {
      nix-homebrew.taps."AidanWright/homebrew-zoho" = inputs.homebrew-zoho;
      homebrew.casks = [
        "zoho-workdrive-truesync"
        "zoho-trident"
      ];
    };
}
