# modules/programs/cli/git.nix
################################################################################
# Signing keys are user-specific so not kept here.
################################################################################
{ ... }:
{
  flake.aspects.programs.git.homeManager =
    { ... }:
    {
      programs.git.enable = true;
      programs.gh.enable = true;
    };
}
