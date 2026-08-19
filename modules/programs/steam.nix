# modules/programs/steam.nix
################################################################################
# Steam gaming platform.
################################################################################
{ ... }:
{
  flake.aspects.programs.steam.darwin =
    { ... }:
    {
      #homebrew.casks = [ "steam" ];
    };
}
