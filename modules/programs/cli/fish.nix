# modules/programs/cli/fish.nix
################################################################################
# Fish as a login shell. `programs.fish.darwin` enables fish system-wide on
# macOS; `programs.fish.homeManager` is the interactive home config (shared by
# the standalone home and by useFish); the `flake.lib.useFish <user>` factory
# makes fish the login shell for one darwin account:
# `imports = [ (inputs.self.lib.useFish "<user>") ]`.
################################################################################
{ lib, inputs, ... }:
{
  flake.aspects.programs.fish.darwin =
    { pkgs, ... }:
    {
      programs.fish.enable = true;

      # Register fish as a permissible login shell (writes /etc/shells).
      environment.shells = [ pkgs.fish ];
    };

  flake.aspects.programs.fish.homeManager =
    { pkgs, lib, ... }:
    {
      programs.fish = {
        enable = true;
        interactiveShellInit = "set -g fish_greeting";
        shellAbbrs = {
          ".." = "cd ..";
          "..." = "cd ../..";
          gst = "git status";
          gco = "git checkout";
          gp = "git push";
          gl = "git pull";
        };
        generateCompletions = true;
      };

      programs.fzf = {
        enable = true;
        enableFishIntegration = true;
      };

      programs.zoxide = {
        enable = true;
        enableFishIntegration = true;
      };

      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      # fish builds completions from man pages, but only when asked to. Run
      # the generator on activation so `man`-documented flags tab-complete.
      home.activation.fishManCompletions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.fish}/bin/fish -c fish_update_completions || true
      '';

      programs.man.generateCaches = true;
    };

  flake.lib.useFish = user: {
    # nix-darwin only changes a login shell for accounts in `users.knownUsers`,
    # which also requires a literal `uid` (it cannot be read at eval time).
    # Hardcoding uid 501 would assume this host's primary user.
    #
    # This hack bypass that restriction. In the past there was also some worry about adding root
    # to the knownUsers, but *could* be outdated; see:
    # https://github.com/nix-darwin/nix-darwin/issues/1237
    system.activationScripts.preActivation.text = lib.mkAfter ''
      fishPath="/run/current-system/sw/bin/fish"
      if [ -x "$fishPath" ] &&
         [ "$(dscl . -read "/Users/${user}" UserShell 2>/dev/null | awk '{print $2}')" != "$fishPath" ]; then
        echo "setting ${user}'s login shell to fish..." >&2
        dscl . -create "/Users/${user}" UserShell "$fishPath"
      fi
    '';

    home-manager.users.${user}.imports = [ inputs.self.modules.homeManager."programs.fish" ];
  };
}
