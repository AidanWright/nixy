# modules/programs/calibre.nix
################################################################################
# Calibre e-book library plus Amazon's Kindle Previewer.
#
# nixpkgs ships no darwin build of calibre, so it comes from the cask. Kindle
# Previewer bundles the KFX conversion engine that calibre's KFX Output plugin
# drives; installing both is what makes sideloaded books render with Kindle's
# enhanced typesetting over USB.
#
# Calibre plugins live inside calibre and are added manually (Preferences ->
# Plugins): KFX Input/Output for the native Kindle format, and WordDumb to
# build X-Ray and Word Wise files locally instead of relying on Amazon's
# account-gated server sidecars. WordDumb runs a spaCy NLP pipeline, so it
# needs a Python 3.11+ interpreter; pip ships alongside so the plugin can
# fetch its own spaCy models into its data directory. Point WordDumb's
# interpreter preference at /run/current-system/sw/bin/python3.
#
# xray-builder is the standalone CLI that builds handmade-style X-Ray from
# Goodreads data, closer to Amazon's than WordDumb's NLP output. It is pulled
# from nixy-apps' flake output (not the overlay) so it resolves to the exact
# store path nixy-apps' cache holds, substituting prebuilt instead of building.
################################################################################
{ inputs, ... }:
{
  flake.aspects.programs.calibre.darwin =
    { pkgs, ... }:
    {
      homebrew.casks = [
        "calibre"
        "kindle-previewer"
        "openmtp"
      ];

      homebrew.masApps."Amazon Kindle" = 302584613;

      environment.systemPackages = [
        (pkgs.python3.withPackages (pythonPackages: [ pythonPackages.pip ]))
        #inputs.nixy-apps.packages.${pkgs.stdenv.hostPlatform.system}.xray-builder
      ];
    };
}
