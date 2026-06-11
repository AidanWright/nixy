# modules/programs/stremio.nix
################################################################################
# Stremio media streaming app.
################################################################################
{ ... }:
{
  flake.modules.darwin.stremio =
    { ... }:
    {
      #homebrew.casks = [ "stremio" ];
    };
}
