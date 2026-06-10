# modules/system/basic/darwin/desktop.nix
################################################################################
# Desktop appearance: dock, Finder, and global UI defaults.
################################################################################
{ ... }:
{
  flake.modules.darwin.desktop =
    { config, ... }:
    {
      # can be enabled for a more windows-like environment
      #homebrew.casks = [ "taskbar" ];
      homebrew.casks = [ "dockdoor" ];
      system.defaults.dock.autohide = false;
      system.defaults.dock.show-recents = false;
      system.defaults.dock.minimize-to-application = true;
      system.defaults.dock.orientation = "bottom";
      system.defaults.dock.persistent-apps = [
        { app = "/Applications/QSpace Pro.app"; }
        { app = "/System/Applications/Apps.app"; }
        { spacer.small = true; }
        { app = "/Applications/Nix Apps/LibreWolf.app"; }
        { app = "/System/Applications/Messages.app"; }
        { app = "/Applications/Trident.app"; }
        { app = "/Applications/Nix Apps/Spotify.app"; }
        { app = "/System/Applications/Utilities/Terminal.app"; }
        { app = "/System/Applications/System Settings.app"; }
        { spacer.small = true; }
      ];
      system.defaults.dock.persistent-others = [
        {
          folder = {
            path = "/Users/${config.system.primaryUser}/Downloads";
            showas = "fan";
            arrangement = "date-modified";
            displayas = "stack";
          };
        }
      ];
      system.defaults.dock.show-process-indicators = true;
      system.defaults.WindowManager.StandardHideWidgets = true;
      system.defaults.dock.tilesize = 64;
      # 1: Disabled, 4: Desktop, 5: Start Screen Saver, 13: Lock Screen
      system.defaults.dock.wvous-bl-corner = 4;
      system.defaults.dock.wvous-br-corner = 13;
      system.defaults.dock.wvous-tl-corner = 1;
      system.defaults.dock.wvous-tr-corner = 1;

      system.defaults.NSGlobalDomain.AppleInterfaceStyle = "Dark";
      system.defaults.NSGlobalDomain.AppleIconAppearanceTheme = "RegularDark";

      system.defaults.NSGlobalDomain.InitialKeyRepeat = 15;
      system.defaults.NSGlobalDomain.KeyRepeat = 2;

      system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;
      system.defaults.NSGlobalDomain.AppleShowAllFiles = true;
      system.defaults.finder.AppleShowAllExtensions = true;
      system.defaults.finder.ShowPathbar = true;
      system.defaults.finder.ShowStatusBar = true;
      system.defaults.finder._FXSortFoldersFirst = true;
      system.defaults.finder._FXSortFoldersFirstOnDesktop = true;
      system.defaults.finder.CreateDesktop = true;
      system.defaults.finder.FXEnableExtensionChangeWarning = false;
      # “icnv” = Icon view, “Nlsv” = List view, “clmv” = Column View, “Flwv” = Gallery View
      system.defaults.finder.FXPreferredViewStyle = "Nlsv";
      # Remove items in the trash after 30 days
      system.defaults.finder.FXRemoveOldTrashItems = true;
      system.defaults.finder.ShowRemovableMediaOnDesktop = false;

      system.defaults.NSGlobalDomain.NSStatusItemSelectionPadding = 12;
      system.defaults.NSGlobalDomain.NSStatusItemSpacing = 6;

      system.defaults.SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;

      system.defaults.controlcenter.BatteryShowPercentage = true;

    };
}
