# modules/system/basic/darwin/desktop.nix
################################################################################
# Desktop appearance: dock, Finder, Stage Manager, and global UI defaults.
################################################################################
{ ... }:
{
  flake.modules.darwin.desktop =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      environment.systemPackages = with pkgs; [
        unstable.librewolf
        rectangle
      ];

      launchd.user.agents.defaultBrowser = {
        serviceConfig = {
          ProgramArguments = [
            "${pkgs.defaultbrowser}/bin/defaultbrowser"
            "librewolf"
          ];
          RunAtLoad = true;
          StandardOutPath = "/tmp/defaultbrowser.log";
          StandardErrorPath = "/tmp/defaultbrowser.log";
        };
      };

      launchd.user.agents.wallpaper = {
        serviceConfig = {
          ProgramArguments = [
            "/usr/bin/osascript"
            "-e"
            ''tell application "Finder" to set desktop picture to POSIX file "${config.stylix.image}"''
          ];
          RunAtLoad = true;
        };
      };

      homebrew.casks = [
        "dockdoor"
        "qspace-pro"
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
            in
            [
              { app = "/Applications/QSpace Pro.app"; }
              { app = "/System/Applications/Apps.app"; }
              { spacer.small = true; }
              { app = "/Applications/Nix Apps/LibreWolf.app"; }
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
