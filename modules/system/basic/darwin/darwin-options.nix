# modules/system/basic/darwin/darwin-options.nix
################################################################################
# Clean option interfaces for macOS settings whose raw defaults keys or values
# are not self-documenting. desktop.nix and basic.nix set options.darwin.*;
# this module translates them to the underlying system.defaults entries.
################################################################################
{ ... }:
{
  flake.modules.darwin.darwinOptions =
    { lib, config, ... }:
    let
      cfg = config.darwin;

      cornerActions = {
        disabled = 1;
        missionControl = 2;
        applicationWindows = 3;
        desktop = 4;
        startScreenSaver = 5;
        disableScreenSaver = 6;
        sleep = 10;
        launchpad = 11;
        notificationCenter = 12;
        lockScreen = 13;
        quickNote = 14;
      };
      cornerType = lib.types.enum (builtins.attrNames cornerActions);

      finderViews = {
        icons = "icnv";
        list = "Nlsv";
        columns = "clmv";
        gallery = "Flwv";
      };

      sidebarSizes = {
        small = 1;
        medium = 2;
        large = 3;
      };

      titleBarActions = {
        zoom = "Maximize";
        minimize = "Minimize";
        none = "None";
      };

      predefinedTintColors = [
        "Blue"
        "Purple"
        "Pink"
        "Red"
        "Orange"
        "Yellow"
        "Green"
        "Graphite"
        "Multicolor"
      ];

      clickPressures = {
        light = 0;
        medium = 1;
        firm = 2;
      };

      spotlightCategories = {
        applications = "APPLICATIONS";
        contacts = "CONTACT";
        calculator = "CALCULATOR";
        calendar = "CALENDAR";
        reminders = "EVENTS_AND_REMINDERS";
        mail = "MAIL";
        messages = "MESSAGES";
        notes = "NOTES";
        documents = "DOCUMENTS";
        folders = "FOLDERS";
        fonts = "FONTS";
        images = "IMAGES";
        developer = "SOURCE";
        bookmarks = "BOOKMARKS";
        systemSettings = "SYSTEM_PREFS";
        presentations = "PRESENTATIONS";
        spreadsheets = "SPREADSHEETS";
        music = "MUSIC";
        movies = "MOVIES";
        news = "NEWS";
        websites = "WEBSITES";
        definitions = "DEFINITION";
        tips = "TIPS";
        books = "BOOKS";
        conversion = "CONVERSION";
        menuItems = "MENU_ITEMS";
      };
      allCategoryNames = builtins.attrNames spotlightCategories;

      isCustomTint =
        cfg.appearance.iconTintColor != null
        && !builtins.elem cfg.appearance.iconTintColor predefinedTintColors;

      lookUpMap = {
        forceClick = {
          threeFingerTap = 0;
          forceClickEnabled = true;
        };
        threeFingerTap = {
          threeFingerTap = 2;
          forceClickEnabled = false;
        };
        disabled = {
          threeFingerTap = 0;
          forceClickEnabled = false;
        };
      };
    in
    {
      options.darwin = {
        hotCorners = {
          topLeft = lib.mkOption {
            type = cornerType;
            default = "disabled";
            description = "Action triggered when the cursor moves to the top-left corner of the screen.";
          };
          topRight = lib.mkOption {
            type = cornerType;
            default = "disabled";
            description = "Action triggered when the cursor moves to the top-right corner of the screen.";
          };
          bottomLeft = lib.mkOption {
            type = cornerType;
            default = "disabled";
            description = "Action triggered when the cursor moves to the bottom-left corner of the screen.";
          };
          bottomRight = lib.mkOption {
            type = cornerType;
            default = "disabled";
            description = "Action triggered when the cursor moves to the bottom-right corner of the screen.";
          };
        };

        finder.defaultView = lib.mkOption {
          type = lib.types.enum (builtins.attrNames finderViews);
          default = "list";
          description = "Default view style for new Finder windows.";
        };

        appearance = {
          sidebarIconSize = lib.mkOption {
            type = lib.types.enum (builtins.attrNames sidebarSizes);
            default = "medium";
            description = "Size of icons in Finder sidebars and other list views.";
          };
          iconTintColor = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = ''
              Tint color for icons and widgets. Use a predefined name
              ("Blue", "Purple", "Pink", "Red", "Orange", "Yellow", "Green",
              "Graphite", "Multicolor") or a custom macOS RGBA string like
              "1.0 0.699742 0.475 0.687281". null uses the system default.
            '';
          };
        };

        dock.titleBarDoubleClick = lib.mkOption {
          type = lib.types.enum (builtins.attrNames titleBarActions);
          default = "zoom";
          description = "Action when double-clicking a window title bar. Matches the System Settings label.";
        };

        scrollBars.clickAction = lib.mkOption {
          type = lib.types.enum [
            "jumpToNextPage"
            "jumpToClickedPosition"
          ];
          default = "jumpToNextPage";
          description = "What happens when clicking in an empty area of the scroll bar track.";
        };

        menuBar.hideSpotlightIcon = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Remove the Spotlight magnifying glass from the menu bar.";
        };

        stageManager.groupWindowsFromSameApp = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Show all windows from the same app at once in Stage Manager (All at Once).";
        };

        widgets.showOnDesktop = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Show widgets on the desktop when not in Stage Manager.";
        };

        trackpad = {
          tapToClick = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Tap the trackpad with one finger to click.";
          };
          secondaryClick = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Tap or click with two fingers to right-click.";
          };
          forceClick = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Press firmly for Force Click and haptic feedback.";
          };
          clickPressure = lib.mkOption {
            type = lib.types.enum (builtins.attrNames clickPressures);
            default = "medium";
            description = "Physical pressure required to register a click.";
          };
          lookUpGesture = lib.mkOption {
            type = lib.types.enum [
              "forceClick"
              "threeFingerTap"
              "disabled"
            ];
            default = "forceClick";
            description = "Gesture used for Look Up and data detectors.";
          };
          trackingSpeed = lib.mkOption {
            type = lib.types.float;
            default = 1.0;
            description = "Cursor tracking speed (0 = slow, 3 = fast).";
          };
        };

        keyboard = {
          navigation = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Use Tab to move focus between all controls, not just text fields.";
          };
          brightnessInLowLight = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Automatically adjust keyboard brightness in low-light conditions.";
          };
          dimAfterSeconds = lib.mkOption {
            type = lib.types.int;
            default = 30;
            description = "Seconds of inactivity before the keyboard backlight turns off. 0 disables the timeout.";
          };
        };

        spotlight = {
          showRelatedContent = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Show content from Apple services related to the current search result.";
          };
          helpImproveSearch = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Send search queries and usage data to Apple to improve Spotlight suggestions.";
          };
          enabledCategories = lib.mkOption {
            type = lib.types.listOf (lib.types.enum allCategoryNames);
            default = allCategoryNames;
            description = "Search result categories shown in Spotlight results.";
          };
        };

        siri = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable Siri and show the Siri icon in the menu bar.";
          };
          enableAppleIntelligence = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable Apple Intelligence features system-wide.";
          };
        };
      };

      config = {
        system.defaults.dock = {
          wvous-tl-corner = cornerActions.${cfg.hotCorners.topLeft};
          wvous-tr-corner = cornerActions.${cfg.hotCorners.topRight};
          wvous-bl-corner = cornerActions.${cfg.hotCorners.bottomLeft};
          wvous-br-corner = cornerActions.${cfg.hotCorners.bottomRight};
        };

        system.defaults.finder.FXPreferredViewStyle = finderViews.${cfg.finder.defaultView};

        system.defaults.NSGlobalDomain = {
          NSTableViewDefaultSizeMode = sidebarSizes.${cfg.appearance.sidebarIconSize};
          AppleScrollerPagingBehavior = cfg.scrollBars.clickAction == "jumpToClickedPosition";
          AppleKeyboardUIMode = if cfg.keyboard.navigation then 2 else 0;
          "com.apple.trackpad.scaling" = cfg.trackpad.trackingSpeed;
          "com.apple.trackpad.forceClick" = lookUpMap.${cfg.trackpad.lookUpGesture}.forceClickEnabled;
        };

        system.defaults.trackpad = {
          Clicking = cfg.trackpad.tapToClick;
          TrackpadRightClick = cfg.trackpad.secondaryClick;
          ActuateDetents = cfg.trackpad.forceClick;
          ForceSuppressed = !cfg.trackpad.forceClick;
          FirstClickThreshold = clickPressures.${cfg.trackpad.clickPressure};
          SecondClickThreshold = clickPressures.${cfg.trackpad.clickPressure};
          TrackpadThreeFingerTapGesture = lookUpMap.${cfg.trackpad.lookUpGesture}.threeFingerTap;
        };

        system.defaults.WindowManager = {
          AppWindowGroupingBehavior = cfg.stageManager.groupWindowsFromSameApp;
          StandardHideWidgets = !cfg.widgets.showOnDesktop;
        };

        system.defaults.CustomUserPreferences = {
          "NSGlobalDomain" = {
            AppleActionOnDoubleClick = titleBarActions.${cfg.dock.titleBarDoubleClick};
          }
          // lib.optionalAttrs (cfg.appearance.iconTintColor != null) (
            {
              AppleIconAppearanceTintColor = if isCustomTint then "Other" else cfg.appearance.iconTintColor;
            }
            // lib.optionalAttrs isCustomTint {
              AppleIconAppearanceCustomTintColor = cfg.appearance.iconTintColor;
            }
          );

          "com.apple.Spotlight" = {
            "NSStatusItem VisibleCC Item-0" = !cfg.menuBar.hideSpotlightIcon;
            showRelatedContentEnabled = cfg.spotlight.showRelatedContent;
            improveSuggestionsEnabled = cfg.spotlight.helpImproveSearch;
            orderedItems = map (name: {
              enabled = if builtins.elem name cfg.spotlight.enabledCategories then 1 else 0;
              name = spotlightCategories.${name};
            }) allCategoryNames;
          };

          "com.apple.BezelServices" =
            lib.mkIf (cfg.keyboard.brightnessInLowLight || cfg.keyboard.dimAfterSeconds > 0)
              {
                kDim = cfg.keyboard.brightnessInLowLight;
                kDimTime = lib.mkIf (cfg.keyboard.dimAfterSeconds > 0) cfg.keyboard.dimAfterSeconds;
              };

          "com.apple.Siri" = lib.mkIf (!cfg.siri.enable) {
            StatusMenuVisible = false;
            SiriPrefStashedStatusMenuVisible = false;
            VoiceTriggerUserTrainingCompletionRequired = false;
          };

          "com.apple.CloudSubscriptionFeatures" = lib.mkIf (!cfg.siri.enableAppleIntelligence) {
            "config.enabled" = false;
          };
        };
      };
    };
}
