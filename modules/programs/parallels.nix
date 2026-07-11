# modules/programs/parallels.nix
################################################################################
# Desktop virtualization software
################################################################################
{ ... }:
{
  flake.aspects.programs.parallels.darwin =
    { ... }:
    {
      homebrew.casks = [ "parallels" ];
    };
}
