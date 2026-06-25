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

  flake.aspects.programs.office.darwin =
    { ... }:
    {
      nix-homebrew.taps."AidanWright/homebrew-zoho" = inputs.homebrew-zoho;
      # nix-homebrew symlinks taps from the Nix store, making this a custom-remote
      # tap that Homebrew's default tap-trust gate refuses. Per-cask trust is not
      # allowed for custom-remote taps, so the whole (self-owned) tap is trusted.
      nix-homebrew.trust.taps = [ "aidanwright/zoho" ];
      homebrew.casks = [
        "zoho-workdrive-truesync"
        "zoho-trident"
      ];
      system.defaults.CustomUserPreferences."com.zoho.trident.direct".MenuBarState = 0;
    };
}
