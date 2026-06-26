# modules/programs/office.nix
################################################################################
# Stub to customize anki flashcard app 
################################################################################
{ ... }:
{
  flake.aspects.programs.anki.homeManager =
    { ... }:
    {
      programs.anki.enable = true;
    };
}
