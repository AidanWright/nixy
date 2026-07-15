# modules/programs/cli/fish.nix
################################################################################
# Fish as a login shell. The `programs.fish` aspect enables fish system-wide;
# the `flake.lib.useFish <user>` factory turns it on for one account
# `imports = [ (inputs.self.lib.useFish "<user>") ]`.
################################################################################
{ lib, ... }:
{
  flake.aspects.programs.fish.darwin =
    { pkgs, ... }:
    {
      programs.fish.enable = true;

      # Register fish as a permissible login shell (writes /etc/shells).
      environment.shells = [ pkgs.fish ];
    };

  flake.lib.useFish = user: {
    # nix-darwin only changes a login shell for accounts in `users.knownUsers`,
    # which also requires a literal `uid` (it cannot be read at eval time).
    # Hardcoding uid 501 would assume this host's primary user.
    #
    # This hack bypass that restriction. In the past there was also some worry about adding root
    # to the knownUsers, but *could* be outdated; see:
    # https://github.com/nix-darwin/nix-darwin/issues/1237
    #
    # Instead, we use a factory flake pattern and enable in user module.
    system.activationScripts.postActivation.text = lib.mkAfter ''
      fishPath="/run/current-system/sw/bin/fish"
      if [ "$(dscl . -read "/Users/${user}" UserShell 2>/dev/null | awk '{print $2}')" != "$fishPath" ]; then
        echo "setting ${user}'s login shell to fish..." >&2
        dscl . -create "/Users/${user}" UserShell "$fishPath"
      fi
    '';

    home-manager.users.${user} =
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

        # fish defaults this on to build an apropos cache, but home-manager
        # ships no man package on darwin >= 26.05 (it defers to system man), so
        # the cache can never build and only emits a warning. Completions still
        # come from fish_update_completions above.
        programs.man.generateCaches = true;
      };
  };
}
