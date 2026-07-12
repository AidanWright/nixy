# modules/programs/cli/starship.nix
################################################################################
# Single-line powerline prompt (plus a prompt character on the next line). Each
# section's leading arrow uses starship's `prev_bg` colour, which resolves to
# the previous *non-empty* module's background. That keeps the line continuous:
# a section's arrow appears only when the section does, and always matches the
# colour behind it, whatever section happens to be there. Colours come from the
# gruvbox palette below. A user aspect can add a second line via the
# `local.starshipExtraLine` option (see modules/users/admin/admin.nix).
################################################################################
{ ... }:
{
  flake.aspects.programs.starship.homeManager =
    { lib, config, ... }:
    let
      # An arrow from the previous section into `bg`, then the body on `bg`.
      # `prev_bg` follows whatever non-empty section precedes it, so this stays
      # correct no matter which optional sections are present.
      seg = bg: body: "[](fg:prev_bg bg:${bg})[ ${body} ](fg:color_fg0 bg:${bg})";

      langFormat = seg "color_green" "$symbol($version)";
    in
    {
      # A per-user aspect can append a second prompt line (a role banner, a
      # warning) by setting this, rather than overriding the whole format string.
      options.local.starshipExtraLine = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "[  ADMIN SHELL ](bold fg:color_red)";
        description = "Starship format inserted after the main line's break, before the prompt character.";
      };

      config.programs.starship = {
        enable = true;
        enableFishIntegration = true;
        presets = [ "nerd-font-symbols" ];
        settings = {
          add_newline = true;
          format = lib.concatStrings [
            "[](fg:color_orange)"
            "$os"
            "$username"
            "$directory"
            "$git_branch"
            "$git_state"
            "$git_status"
            "$nix_shell"
            "$nodejs"
            "$python"
            "$rust"
            "$golang"
            "$cmd_duration"
            "[](fg:prev_bg)"
            "$line_break"
            config.local.starshipExtraLine
            "$character"
          ];
          palette = lib.mkForce "gruvbox_dark";
          palettes.gruvbox_dark = {
            color_fg0 = "#fbf1c7";
            color_bg1 = "#3c3836";
            color_bg3 = "#665c54";
            color_blue = "#458588";
            color_aqua = "#689d6a";
            color_green = "#98971a";
            color_orange = "#d65d0e";
            color_purple = "#b16286";
            color_red = "#cc241d";
            color_yellow = "#d79921";
            color_black = "#000000";
          };
          os = {
            disabled = false;
            style = "bg:color_orange fg:color_fg0";
          };
          username = {
            show_always = true;
            style_user = "bg:color_orange fg:color_fg0";
            style_root = "bold bg:color_orange fg:color_red";
            format = "[ $user ]($style)";
          };
          directory = {
            format = seg "color_yellow" "$path";
            truncation_length = 3;
            truncate_to_repo = true;
            read_only = " ";
          };
          git_branch = {
            symbol = "";
            format = seg "color_aqua" "$symbol $branch";
          };
          git_state.style = "fg:color_fg0 bg:color_aqua";
          # git_status continues the aqua run started by the branch, so it has
          # no arrow of its own; the optional group hides it on a clean repo.
          git_status.format = "([\\[$all_status$ahead_behind\\]](fg:color_fg0 bg:color_aqua))";
          nix_shell = {
            symbol = "";
            heuristic = true;
            # The new `nix shell nixpkgs#...` exports neither IN_NIX_SHELL nor a
            # name, so starship can only detect it heuristically: purity is
            # unknown and there is no name. Label the unknown state "impure" and
            # show the name only when one exists (old nix-shell / nix develop).
            unknown_msg = "impure";
            format = seg "color_blue" "$symbol $state( \\($name\\))";
          };
          nodejs.format = langFormat;
          python.format = langFormat;
          rust.format = langFormat;
          golang.format = langFormat;
          cmd_duration = {
            min_time = 2000;
            format = seg "color_bg1" "$duration";
          };
          character = {
            success_symbol = "[](bold fg:color_green)";
            error_symbol = "[](bold fg:color_red)";
            vimcmd_symbol = "[](bold fg:color_green)";
            vimcmd_replace_one_symbol = "[](bold fg:color_purple)";
            vimcmd_replace_symbol = "[](bold fg:color_purple)";
            vimcmd_visual_symbol = "[](bold fg:color_yellow)";
          };
        };
      };
    };
}
