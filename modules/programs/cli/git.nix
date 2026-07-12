# modules/programs/cli/git.nix
################################################################################
# Git plus the GitHub CLI credential helper for the user that imports it. gh's
# helper wires github.com and gist.github.com by default and resolves to
# `${pkgs.gh}` in the store, so the path tracks the flake and stays a GC root
# instead of freezing to whatever gh version `gh auth setup-git` last wrote.
# User identity and signing keys are personal, so they live in the user's own
# module rather than this shared aspect.
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
