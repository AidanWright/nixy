# modules/system/basic/desktop.nix
################################################################################
# Desktop appearance: dock, Finder, Stage Manager, and global UI defaults.
################################################################################
{ ... }:
{
  flake.aspects.desktop.darwin =
    { config, ... }:
    {
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
        # The Dock is per-user and lives in modules/users/aidanwright/ (the `dock`
        # home-manager aspect), so non-primary users (e.g. admin) get the default.

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
