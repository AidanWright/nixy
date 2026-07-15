# modules/system/basic/settings.nix
################################################################################
# Basic system settings: power management, input devices, privacy, and search.
# Highly opinionated but represents sensible defaults.
################################################################################
{ ... }:
{
  flake.aspects =
    { aspects, ... }:
    {
      basic.desktop = {
        includes = with aspects; [ options.base ];

        darwin =
          { pkgs, config, ... }:
          {
            environment.systemPackages = [ pkgs.darwinApps.dockdoor ];

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
              "qspace-pro" # finder alternative
            ];

            system.defaults = {
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

            power.sleep = {
              display = 5;
              computer = 10;
              harddisk = 5;
            };

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

              trackpad = {
                tapToClick = true;
                secondaryClick = true;
                forceClick = true;
                clickPressure = "medium";
                lookUpGesture = "forceClick";
                trackingSpeed = 1.0;
              };

              keyboard = {
                navigation = true;
                brightnessInLowLight = true;
                dimAfterSeconds = 30;
              };

              spotlight = {
                showRelatedContent = true;
                helpImproveSearch = false;
                enabledCategories = [
                  "applications"
                  "books"
                  "calculator"
                  "calendar"
                  "contacts"
                  "definitions"
                  "mail"
                  "messages"
                  "notes"
                  "music"
                  "movies"
                  "systemSettings"
                  "websites"
                  "developer"
                ];
              };
            };

            system.defaults.hitoolbox.AppleFnUsageType = "Show Emoji & Symbols";
          };
      };
    };
}
