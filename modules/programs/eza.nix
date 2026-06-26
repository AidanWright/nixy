# modules/programs/eza.nix
################################################################################
# eza as the ls replacement, with its fish integration providing the
# ls/ll/la/lt aliases.
################################################################################
{ ... }:
{
  flake.aspects.programs.eza.homeManager =
    { ... }:
    {
      # enableFishIntegration provides the ls/ll/la/lt/lla aliases that point at
      # eza, so no manual alias wiring is needed here.
      programs.eza = {
        enable = true;
        enableFishIntegration = true;
        git = true;
        icons = "auto";
        extraOptions = [ "--group-directories-first" ];
      };
    };
}
