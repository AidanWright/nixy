# modules/users/aidanwright/aidanwright.nix
################################################################################
# The primary (daily) user. Owns the account record plus aidanwright's
# home-manager setup: the per-user Dock and the claude/spotify homeManager
# aspects, alongside user-facing apps. System program configs (kitty, librewolf,
# ssh) attach to this user from their own aspects via
# `home-manager.users.${primaryUser}` and merge in.
################################################################################
{ inputs, ... }:
{
  flake.aspects.users.aidanwright.darwin =
    { ... }:
    {
      home-manager.users.aidanwright =
        {
          config,
          osConfig,
          pkgs,
          ...
        }:
        {
          imports = [
            inputs.self.modules.homeManager."options.dock"
            inputs.self.modules.homeManager."programs.all"
          ];

          home.packages = with pkgs; [
            rectangle
            mpv
            syncplay
            darwinApps.cryptomator
            darwinApps.stremio
          ];

          # Personal identity for the git tooling enabled by programs.all. The
          # signing key is a GPG (openpgp) fingerprint already in this user's
          # keyring; signByDefault turns on commit and tag signing.
          programs.git = {
            settings.user = {
              name = "Aidan Wright";
              email = "38870143+AidanWright@users.noreply.github.com";
            };
            signing = {
              key = "1810A874AD3037F1";
              format = "openpgp";
              signByDefault = true;
            };
          };

          dock = {
            autohide = false;
            show-recents = false;
            minimize-to-application = true;
            orientation = "bottom";
            show-process-indicators = true;
            tilesize = 64;
            mineffect = "genie";
            launchanim = true;

            persistent-apps =
              let
                spotifyApp =
                  if config.programs ? spicetify then
                    { app = "/Users/aidanwright/Applications/Home Manager Apps/Spotify.app"; }
                  else
                    { app = "/System/Applications/Music.app"; };
                kittyApp =
                  if config.programs.kitty.enable then
                    { app = "/Users/aidanwright/Applications/Home Manager Apps/kitty.app"; }
                  else
                    { app = "/System/Applications/Utilities/Terminal.app"; };
                browserApp =
                  if config.programs.librewolf.enable then
                    { app = "/Users/aidanwright/Applications/Home Manager Apps/LibreWolf.app"; }
                  else
                    { app = "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"; };
                mailApp =
                  let
                    caskNames = map (cask: cask.name or cask) osConfig.homebrew.casks;
                  in
                  if builtins.elem "zoho-trident" caskNames then
                    { app = "/Applications/Trident.app"; }
                  else
                    { app = "/System/Applications/Mail.app"; };
              in
              [
                { app = "/Applications/QSpace Pro.app"; }
                { app = "/System/Applications/Apps.app"; }
                { spacer.small = true; }
                browserApp
                { app = "/System/Applications/Messages.app"; }
                mailApp
                spotifyApp
                kittyApp
                { app = "/System/Applications/System Settings.app"; }
                { spacer.small = true; }
              ];

            persistent-others = [
              {
                folder = {
                  path = "/Users/aidanwright/Downloads";
                  showas = "fan";
                  arrangement = "date-modified";
                  displayas = "stack";
                };
              }
            ];
          };
        };
    };
}
