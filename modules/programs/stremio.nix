# modules/programs/stremio.nix
################################################################################
# Stremio media streaming app.
################################################################################
{ ... }:
{
  flake.aspects.programs.stremio.darwin =
    { ... }:
    {
      #homebrew.casks = [ "stremio" ];
    };
}
