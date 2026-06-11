# modules/programs/kitty/kitty.nix
################################################################################
# Configures kitty terminal via home-manager.
################################################################################
{ ... }:
{
  flake.modules.darwin.kitty =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      #environment.systemPackages = [ pkgs.kitty ];
      home-manager.users.${config.system.primaryUser} = {
        programs.kitty = {
          enable = true;
          settings = {
            scrollback_lines = 10000;
            enable_audio_bell = false;
            window_padding_width = 8;
            confirm_os_window_close = 0;
          };
        };
        stylix.targets.kitty.enable = true;
      };

      system.activationScripts.postActivation.text = lib.mkAfter ''
        kittyApp="/Users/${config.system.primaryUser}/Applications/Home Manager Apps/kitty.app"
        if [ -d "$kittyApp/Contents/Resources" ]; then
          cp ${./whiskers.icns} "$kittyApp/Contents/Resources/kitty.icns"
          plutil -remove CFBundleIconName "$kittyApp/Contents/Info.plist" 2>/dev/null || true
          xattr -d com.apple.FinderInfo "$kittyApp" 2>/dev/null || true
          touch "$kittyApp"
        fi
      '';
    };
}
