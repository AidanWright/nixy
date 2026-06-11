# modules/system/basic/darwin/desktop.nix
################################################################################
# Desktop appearance: dock, Finder, and global UI defaults.
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

      system.activationScripts.postActivation.text = lib.mkAfter ''
        kittyResources="/Applications/Nix Apps/kitty.app/Contents/Resources"
        if [ -d "$kittyResources" ]; then
          cp ${./whiskers.icns} "$kittyResources/kitty.icns"
          touch "/Applications/Nix Apps/kitty.app"
        fi
      '';

      system.defaults = {
        dock = {
          autohide = false;
          show-recents = false;
          minimize-to-application = true;
          orientation = "bottom";
          show-process-indicators = true;
          tilesize = 64;
          # 1: Disabled, 4: Desktop, 5: Start Screen Saver, 13: Lock Screen
          wvous-bl-corner = 4;
          wvous-br-corner = 13;
          wvous-tl-corner = 1;
          wvous-tr-corner = 1;
          persistent-apps = [
            { app = "/Applications/QSpace Pro.app"; }
            { app = "/System/Applications/Apps.app"; }
            { spacer.small = true; }
            { app = "/Applications/Nix Apps/LibreWolf.app"; }
            { app = "/System/Applications/Messages.app"; }
            { app = "/Applications/Trident.app"; }
            { app = "/Applications/Nix Apps/Spotify.app"; }
            { app = "/Applications/Nix Apps/kitty.app"; }
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

        WindowManager.StandardHideWidgets = true;

        NSGlobalDomain = {
          AppleInterfaceStyle = "Dark";
          AppleIconAppearanceTheme = "TintedDark";
          InitialKeyRepeat = 15;
          KeyRepeat = 2;
          AppleShowAllExtensions = true;
          AppleShowAllFiles = true;
          NSStatusItemSelectionPadding = 24;
          NSStatusItemSpacing = 12;
        };

        finder = {
          AppleShowAllExtensions = true;
          ShowPathbar = true;
          ShowStatusBar = true;
          _FXSortFoldersFirst = true;
          _FXSortFoldersFirstOnDesktop = true;
          CreateDesktop = true;
          FXEnableExtensionChangeWarning = false;
          # "icnv" = Icon, "Nlsv" = List, "clmv" = Column, "Flwv" = Gallery
          FXPreferredViewStyle = "Nlsv";
          FXRemoveOldTrashItems = true;
          ShowRemovableMediaOnDesktop = false;
        };

        SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;

        controlcenter = {
          BatteryShowPercentage = true;
          NowPlaying = false;
        };

        CustomUserPreferences = {
          "NSGlobalDomain".AppleIconAppearanceTintColor = "Other";
          "NSGlobalDomain".AppleIconAppearanceCustomTintColor = "1.000000 0.699742 0.475000 0.687281";
          "com.apple.Spotlight"."NSStatusItem VisibleCC Item-0" = false;
          "com.ethanbills.DockDoor".showMenuBarIcon = false;
          "com.jinghaoshe.qspace.pro".settings_hidden_visible = 1;
        };
      };
    };
}
