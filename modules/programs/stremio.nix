# modules/programs/stremio.nix
################################################################################
# Stremio media streaming app.
################################################################################
{ ... }:
{
  flake.aspects.stremio.darwin =
    { ... }:
    {
      #homebrew.casks = [ "stremio" ];
    };
}
