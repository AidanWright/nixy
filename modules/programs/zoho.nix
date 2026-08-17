# modules/programs/zoho.nix
################################################################################
# Zoho office suite: WorkDrive and Trident.
################################################################################
{ inputs, ... }:
{
  flake-file.inputs.homebrew-zoho = {
    url = "github:AidanWright/homebrew-zoho";
    flake = false;
  };

  flake.aspects.programs.zoho.darwin =
    { ... }:
    {
      nix-homebrew.taps."aidanwright/homebrew-zoho" = inputs.homebrew-zoho;
      nix-homebrew.trust.taps = [ "aidanwright/zoho" ];
      homebrew.casks = [
        "zoho-workdrive-truesync"
        "zoho-trident"
      ];
      system.defaults.CustomUserPreferences."com.zoho.trident.direct".MenuBarState = 0;
    };
}
