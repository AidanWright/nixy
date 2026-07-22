# modules/programs/syncplay/syncplay.nix
################################################################################
# Syncplay (https://syncplay.pl/, https://github.com/Syncplay/syncplay) keeps
# media players in sync across multiple viewers. Wraps pkgs.syncplay into a
# macOS .app bundle so it launches from Finder/Launchpad like a native app.
################################################################################
{ ... }:
{
  flake.aspects.programs.syncplay.homeManager =
    { pkgs, ... }:
    let
      syncplayVersion = pkgs.syncplay.version;

      syncplayApp = pkgs.symlinkJoin {
        name = "syncplay-with-app-${syncplayVersion}";
        paths = [ pkgs.syncplay ];
        nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
        postBuild = ''
          contents="$out/Applications/Syncplay.app/Contents"
          mkdir -p "$contents/MacOS"

          printf 'APPL????' > "$contents/PkgInfo"

          cat > "$contents/Info.plist" <<EOF
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
            <key>CFBundleExecutable</key><string>Syncplay</string>
            <key>CFBundleIdentifier</key><string>pl.syncplay.syncplay</string>
            <key>CFBundleName</key><string>Syncplay</string>
            <key>CFBundlePackageType</key><string>APPL</string>
            <key>CFBundleSignature</key><string>????</string>
            <key>CFBundleShortVersionString</key><string>${syncplayVersion}</string>
            <key>NSHighResolutionCapable</key><true/>
          </dict>
          </plist>
          EOF

          makeBinaryWrapper "$out/bin/syncplay" "$contents/MacOS/Syncplay"
        '';
      };
    in
    {
      home.packages = [ syncplayApp ];
    };
}
