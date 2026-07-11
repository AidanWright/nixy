# modules/programs/cli/fish.nix
################################################################################
# Fish as the primary user's login shell, plus its interactive integrations:
# fzf (Ctrl-R/Ctrl-T/Alt-C), zoxide (`z`), direnv, and man-page completions.
################################################################################
{ ... }:
{
  flake.aspects.programs.fish.darwin =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      programs.fish.enable = true;

      # Register fish as a permissible login shell (writes /etc/shells).
      environment.shells = [ pkgs.fish ];

      # nix-darwin only changes a login shell for accounts in `users.knownUsers`,
      # which also requires a literal `uid` (it cannot be read at eval time).
      # Hardcoding uid 501 would assume this host's primary user, breaking the
      # "runnable by anyone" rule, so instead set the shell with the same `dscl`
      # call nix-darwin runs internally (see nix-darwin#811 and #1237). The
      # /run/current-system path is garbage-collection-safe; the guard keeps the
      # write idempotent.
      system.activationScripts.postActivation.text = lib.mkAfter ''
        fishPath="/run/current-system/sw/bin/fish"
        primaryUser="${config.system.primaryUser}"
        if [ "$(dscl . -read "/Users/$primaryUser" UserShell 2>/dev/null | awk '{print $2}')" != "$fishPath" ]; then
          echo "setting $primaryUser's login shell to fish..." >&2
          dscl . -create "/Users/$primaryUser" UserShell "$fishPath"
        fi
      '';

      home-manager.users.${config.system.primaryUser} =
        { lib, ... }:
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
          programs.man.generateCaches = false;
        };
    };
}
