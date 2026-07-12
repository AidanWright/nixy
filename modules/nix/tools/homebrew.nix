# modules/nix/tools/homebrew.nix
################################################################################
# Enables nix-darwin's Homebrew integration so hosts can declare casks and
# brews declaratively.
################################################################################
{ inputs, ... }:
{
  flake-file.inputs.nix-homebrew.url = "github:zhaofengli/nix-homebrew";

  # The nix-homebrew wrapper hardcodes HOMEBREW_NO_AUTO_UPDATE, so cask metadata
  # never refreshes on its own. Pin the cask tap as an input instead: versions
  # then track the flake lock and bump reproducibly with `nix flake update`.
  flake-file.inputs.homebrew-cask = {
    url = "github:Homebrew/homebrew-cask";
    flake = false;
  };

  flake.aspects.homebrew.darwin =
    { config, ... }:
    {
      imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

      homebrew.enable = true;
      # Without upgrade, `brew bundle` only installs missing casks; it never
      # upgrades an already-installed one when its tap declares a newer version.
      homebrew.onActivation.upgrade = true;
      homebrew.onActivation.cleanup = "zap";
      homebrew.taps = builtins.attrNames config.nix-homebrew.taps;

      nix-homebrew = {
        # Install Homebrew under the default prefix
        enable = true;

        # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
        enableRosetta = true;

        # User owning the Homebrew prefix
        user = config.system.primaryUser;

        # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
        mutableTaps = false;

        # Serve cask definitions from the pinned tap in the Nix store rather than
        # Homebrew's never-refreshed API cache. Official taps are trusted by
        # default, so no trust entry is needed.
        taps."homebrew/homebrew-cask" = inputs.homebrew-cask;
      };
    };
}
