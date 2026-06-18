# modules/system/desktop.nix
################################################################################
# Desktop appearance: dock, Finder, Stage Manager, and global UI defaults.
################################################################################
{ ... }:
{
  flake.aspects.desktop.darwin =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      environment.systemPackages = with pkgs; [
        rectangle
        unstable.dorion
        mpv
        syncplay
      ];

      launchd.user.agents.wallpaper = {
        serviceConfig = {
          ProgramArguments = [
            "/usr/bin/osascript"
            "-e"
            ''tell application "System Events" to tell every desktop to set picture to "${config.stylix.image}"''
          ];
          RunAtLoad = true;
          StandardOutPath = "/tmp/wallpaper.log";
          StandardErrorPath = "/tmp/wallpaper.log";
        };
      };

      homebrew.casks = [
        "dockdoor"
        "qspace-pro"
        "cryptomator"
      ];

      darwin = {
        hotCorners = {
          topLeft = "disabled";
          topRight = "disabled";
          bottomLeft = "desktop";
          bottomRight = "lockScreen";
        };

        finder.defaultView = "list";

        appearance = {
          sidebarIconSize = "medium";
          iconTintColor = "1.0 0.699742 0.475 0.687281";
        };

        dock.titleBarDoubleClick = "zoom";
        scrollBars.clickAction = "jumpToNextPage";
        menuBar.hideSpotlightIcon = true;
        stageManager.groupWindowsFromSameApp = true;
        widgets.showOnDesktop = true;
      };

      system.defaults = {
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
              primaryUser = config.system.primaryUser;
              spotifyApp =
                if lib.hasAttr "spicetify" config.programs then
                  { app = "/Applications/Nix Apps/Spotify.app"; }
                else
                  { app = "/System/Applications/Music.app"; };
              kittyApp =
                if config.home-manager.users.${primaryUser}.programs.kitty.enable then
                  { app = "/Users/${primaryUser}/Applications/Home Manager Apps/kitty.app"; }
                else
                  { app = "/System/Applications/Utilities/Terminal.app"; };
              browserApp =
                if config.home-manager.users.${primaryUser}.programs.librewolf.enable then
                  { app = "/Users/${primaryUser}/Applications/Home Manager Apps/LibreWolf.app"; }
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
                path = "/Users/${config.system.primaryUser}/Downloads";
                showas = "fan";
                arrangement = "date-modified";
                displayas = "stack";
              };
            }
          ];
        };

        NSGlobalDomain = {
          AppleInterfaceStyle = "Dark";
          AppleIconAppearanceTheme = "TintedDark";
          AppleShowScrollBars = "Automatic";
          AppleShowAllExtensions = true;
          AppleShowAllFiles = true;
          NSStatusItemSpacing = 12;
          NSStatusItemSelectionPadding = 24;
          InitialKeyRepeat = 15;
          KeyRepeat = 2;
        };

        finder = {
          AppleShowAllExtensions = true;
          ShowPathbar = true;
          ShowStatusBar = true;
          _FXSortFoldersFirst = true;
          _FXSortFoldersFirstOnDesktop = true;
          CreateDesktop = true;
          FXEnableExtensionChangeWarning = false;
          FXRemoveOldTrashItems = true;
          ShowRemovableMediaOnDesktop = false;
        };

        WindowManager.EnableStandardClickToShowDesktop = true;

        SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;

        controlcenter = {
          BatteryShowPercentage = true;
          NowPlaying = false;
          Bluetooth = true;
          Sound = null;
          Display = null;
          FocusModes = null;
          AirDrop = null;
        };

        CustomUserPreferences = {
          "com.ethanbills.DockDoor".showMenuBarIcon = false;
          "com.jinghaoshe.qspace.pro".settings_hidden_visible = 1;
        };
      };
    };
}
