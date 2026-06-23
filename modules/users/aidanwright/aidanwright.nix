# modules/users/aidanwright/aidanwright.nix
################################################################################
# The primary (daily) user. Owns the account record plus aidanwright's
# home-manager setup: the per-user Dock (via the `dock` homeManager aspect) and
# user-facing apps. Program configs (kitty, librewolf, ssh) still attach to this
# user from their own aspects via `home-manager.users.${primaryUser}` and merge
# in; migrating them into here as homeManager aspects is a later step.
################################################################################
{ inputs, ... }:
{
  flake.aspects.aidanwright.darwin =
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
          imports = [ inputs.self.modules.homeManager.dock ];

          # User-facing apps (moved off the system package set).
          home.packages = with pkgs; [
            rectangle
            unstable.dorion
            mpv
            syncplay
          ];

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
                # spicetify lives in the darwin (os) config; kitty/librewolf are
                # this user's home-manager config.
                spotifyApp =
                  if osConfig.programs ? spicetify then
                    { app = "/Applications/Nix Apps/Spotify.app"; }
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
              in
              [
                { app = "/Applications/QSpace Pro.app"; }
                { app = "/System/Applications/Apps.app"; }
                { spacer.small = true; }
                browserApp
                { app = "/System/Applications/Messages.app"; }
                { app = "/Applications/Trident.app"; }
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
