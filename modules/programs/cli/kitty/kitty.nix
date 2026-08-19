# modules/programs/cli/kitty/kitty.nix
################################################################################
# Configures kitty terminal via home-manager.
################################################################################
{ ... }:
{
  flake.aspects.programs.kitty.darwin =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      home-manager.users.${config.system.primaryUser} = {
        programs.kitty = {
          enable = true;
          settings = {
            scrollback_lines = 10000;
            enable_audio_bell = false;
            window_padding_width = 8;
            confirm_os_window_close = 0;
            macos_option_as_alt = "yes";
          };
        };
        stylix.targets.kitty.enable = true;

        # kitty advertises TERM=xterm-kitty, which any host lacking its terminfo
        # rejects. Downgrading only for ssh keeps kitty's own capabilities in
        # local sessions, and `command` avoids the function recursing into
        # itself the way a fish alias would.
        programs.fish.functions.ssh = {
          wraps = "ssh";
          description = "ssh with a TERM that hosts without kitty's terminfo accept";
          body = ''
            if test "$TERM" = xterm-kitty
                TERM=xterm-256color command ssh $argv
            else
                command ssh $argv
            end
          '';
        };
      };

      system.activationScripts.postActivation.text = lib.mkAfter ''
        kittyApp="/Users/${config.system.primaryUser}/Applications/Home Manager Apps/kitty.app"
        lsregister="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
        if [ -d "$kittyApp/Contents/Resources" ]; then
          cp ${./whiskers.icns} "$kittyApp/Contents/Resources/kitty.icns"
          plutil -remove CFBundleIconName "$kittyApp/Contents/Info.plist" 2>/dev/null || true
          xattr -d com.apple.FinderInfo "$kittyApp" 2>/dev/null || true
          touch "$kittyApp"

          # Finder reads the bundle icon directly, but the Dock renders from the
          # icon-services cache. Re-register the bundle, drop the cache, and
          # restart the Dock so the tile picks up the new icon.
          "$lsregister" -f "$kittyApp" 2>/dev/null || true
          rm -rf /Library/Caches/com.apple.iconservices.store 2>/dev/null || true
          killall Dock 2>/dev/null || true
        fi
      '';
    };
}
