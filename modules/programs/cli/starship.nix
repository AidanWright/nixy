# modules/programs/cli/starship.nix
################################################################################
# Two-line starship prompt (directory, git, nix-shell, language versions,
# command duration). Colours come from Stylix; this file shapes the layout.
################################################################################
{ ... }:
{
  flake.aspects.programs.starship.homeManager =
    { lib, ... }:
    {
      # Stylix drives the colour palette; this only shapes the layout: a
      # two-line prompt with directory, git, nix-shell, language versions and
      # command duration, then a colour-coded prompt character on its own line.
      programs.starship = {
        enable = true;
        enableFishIntegration = true;
        settings = {
          add_newline = true;
          format = lib.concatStrings [
            "$directory"
            "$git_branch"
            "$git_status"
            "$git_state"
            "$nix_shell"
            "$nodejs$python$rust$golang"
            "$cmd_duration"
            "$line_break"
            "$character"
          ];
          directory = {
            truncation_length = 3;
            truncate_to_repo = true;
            read_only = " ";
          };
          git_branch.symbol = " ";
          nix_shell = {
            symbol = " ";
            format = "[$symbol$name]($style) ";
          };
          cmd_duration = {
            min_time = 2000;
            format = "took [$duration]($style) ";
          };
          character = {
            success_symbol = "[❯](bold green)";
            error_symbol = "[❯](bold red)";
          };
        };
      };
    };
}
