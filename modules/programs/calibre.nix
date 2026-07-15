# modules/programs/calibre.nix
################################################################################
# Calibre e-book library plus Amazon's Kindle Previewer.
################################################################################
{ ... }:
{
  flake.aspects.programs.calibre.darwin =
    { pkgs, ... }:
    {
      homebrew.casks = [
        "calibre"
        "kindle-previewer" # required for generating kfx for kindle typesetting
        #"openmtp"
      ];

      homebrew.masApps."Amazon Kindle" = 302584613;

      environment.systemPackages = [
        (pkgs.python3.withPackages (pythonPackages: [ pythonPackages.pip ]))
      ];
    };
}
