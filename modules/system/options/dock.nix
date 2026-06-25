# modules/system/options/dock.nix
################################################################################
# Per-user macOS Dock, as a home-manager aspect. Exposes the same option shape
# as nix-darwin's `system.defaults.dock` (persistent-apps/others etc.) but writes
# to the *user's* `com.apple.dock` via home-manager, so each user can have their
# own Dock. The persistent-apps/others -> tile-data converters are ported from
# nix-darwin (modules/system/defaults/dock.nix).
################################################################################
{ ... }:
{
  flake.aspects.options.dock.homeManager =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib) mkOption types;

      persistentAppsType =
        let
          taggedType = types.attrTag {
            app = mkOption {
              description = "An application to add to the dock.";
              type = types.str;
            };
            file = mkOption {
              description = "A file to add to the dock.";
              type = types.str;
            };
            folder = mkOption {
              description = "A folder to add to the dock.";
              type = types.str;
            };
            spacer = mkOption {
              description = "A spacer (small or regular) to add to the dock.";
              type = types.submodule {
                options.small = mkOption {
                  type = types.bool;
                  default = false;
                };
              };
            };
          };
          simpleType = types.either types.str types.path;
          toTagged = path: { app = path; };
        in
        types.nullOr (types.listOf (types.coercedTo simpleType toTagged taggedType));

      persistentAppsApply =
        let
          toTile =
            item:
            if item ? app then
              {
                tile-data.file-data = {
                  _CFURLString = item.app;
                  _CFURLStringType = 0;
                };
              }
            else if item ? spacer then
              {
                tile-data = { };
                tile-type = if item.spacer.small then "small-spacer-tile" else "spacer-tile";
              }
            else if item ? folder then
              {
                tile-data.file-data = {
                  _CFURLString = "file://" + item.folder;
                  _CFURLStringType = 15;
                };
                tile-type = "directory-tile";
              }
            else if item ? file then
              {
                tile-data.file-data = {
                  _CFURLString = "file://" + item.file;
                  _CFURLStringType = 15;
                };
                tile-type = "file-tile";
              }
            else
              item;
        in
        value: if value == null then null else map toTile value;

      persistentOthersType =
        let
          folderType = types.submodule {
            options.path = mkOption { type = types.str; };
            options.arrangement = mkOption {
              type = types.enum [
                "name"
                "date-added"
                "date-modified"
                "date-created"
                "kind"
              ];
              default = "name";
            };
            options.displayas = mkOption {
              type = types.enum [
                "stack"
                "folder"
              ];
              default = "stack";
            };
            options.showas = mkOption {
              type = types.enum [
                "automatic"
                "fan"
                "grid"
                "list"
              ];
              default = "automatic";
            };
          };
          taggedType = types.attrTag {
            file = mkOption {
              description = "A file to add to the dock.";
              type = types.str;
            };
            folder = mkOption {
              description = "A folder to add to the dock.";
              type = types.coercedTo types.str (str: { path = str; }) folderType;
            };
          };
          simpleType = types.either types.str types.path;
          toTagged =
            _path:
            let
              path = builtins.toString _path;
            in
            if lib.strings.hasInfix "." (lib.last (lib.splitString "/" path)) then
              { file = path; }
            else
              { folder = path; };
        in
        types.nullOr (types.listOf (types.coercedTo simpleType toTagged taggedType));

      persistentOthersApply =
        let
          arrangementMap = {
            name = 1;
            date-added = 2;
            date-modified = 3;
            date-created = 4;
            kind = 5;
          };
          displayasMap = {
            stack = 0;
            folder = 1;
          };
          showasMap = {
            automatic = 0;
            fan = 1;
            grid = 2;
            list = 3;
          };
          parseFolder =
            folder:
            builtins.mapAttrs (
              name: val:
              if name == "arrangement" then
                arrangementMap.${val}
              else if name == "displayas" then
                displayasMap.${val}
              else if name == "showas" then
                showasMap.${val}
              else
                val
            ) folder;
          toTile = item: {
            tile-data = {
              file-data = {
                _CFURLString = "file://" + (if item ? folder then item.folder.path else item.file);
                _CFURLStringType = 15;
              };
            }
            // (
              if item ? folder then { inherit (parseFolder item.folder) arrangement displayas showas; } else { }
            );
            tile-type = if item ? folder then "directory-tile" else "file-tile";
          };
        in
        value: if value == null then null else map toTile value;

      boolOpt = mkOption {
        type = types.nullOr types.bool;
        default = null;
      };
    in
    {
      options.dock = {
        autohide = boolOpt;
        show-recents = boolOpt;
        minimize-to-application = boolOpt;
        show-process-indicators = boolOpt;
        launchanim = boolOpt;
        tilesize = mkOption {
          type = types.nullOr types.int;
          default = null;
        };
        orientation = mkOption {
          type = types.nullOr (
            types.enum [
              "bottom"
              "left"
              "right"
            ]
          );
          default = null;
        };
        mineffect = mkOption {
          type = types.nullOr (
            types.enum [
              "genie"
              "suck"
              "scale"
            ]
          );
          default = null;
        };
        persistent-apps = mkOption {
          type = persistentAppsType;
          default = null;
          apply = persistentAppsApply;
          description = "Persistent applications, spacers, files, and folders in the dock.";
        };
        persistent-others = mkOption {
          type = persistentOthersType;
          default = null;
          apply = persistentOthersApply;
          description = "Persistent files and folders in the dock.";
        };
      };

      config = {
        targets.darwin.defaults."com.apple.dock" = lib.filterAttrs (_: value: value != null) config.dock;
        # The Dock only re-reads its prefs on relaunch.
        home.activation.restartDock = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          /usr/bin/killall Dock 2>/dev/null || true
        '';
      };
    };
}
