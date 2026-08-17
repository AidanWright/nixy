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
    { config, lib, ... }:
    {
      imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

      homebrew.enable = true;
      # `brew bundle` runs as this user, so it must match the prefix owner
      homebrew.user = config.nix-homebrew.user;
      # Without upgrade, `brew bundle` only installs missing casks; it never
      # upgrades an already-installed one when its tap declares a newer version.
      homebrew.onActivation.upgrade = true;
      homebrew.onActivation.cleanup = "zap";
      homebrew.taps = lib.mapAttrsToList (name: _: {
        inherit name;
        trusted = true;
      }) config.nix-homebrew.taps;

      nix-homebrew = {
        # Install Homebrew under the default prefix
        enable = true;

        # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
        enableRosetta = true;

        # typically, the primaryUser will have sudo, but if not, this should be overriden to an account that does
        # (e.g. admin if using the hardening profile)
        user = lib.mkDefault config.system.primaryUser;

        # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
        mutableTaps = false;

        taps."homebrew/homebrew-cask" = inputs.homebrew-cask;
      };
    };
}
