# modules/programs/office.nix
################################################################################
# Zoho office suite: WorkDrive and Trident.
################################################################################
{ inputs, ... }:
{
  flake-file.inputs.homebrew-zoho = {
    url = "github:AidanWright/homebrew-zoho";
    flake = false;
  };

  flake.modules.darwin.office =
    { ... }:
    {
      nix-homebrew.taps."AidanWright/homebrew-zoho" = inputs.homebrew-zoho;
      homebrew.casks = [
        "zoho-workdrive-truesync"
        "zoho-trident"
      ];
      system.defaults.CustomUserPreferences."com.zoho.trident.direct".MenuBarState = 0;
    };
}
