# modules/programs/anki/anki.nix
################################################################################
# Anki flashcard app, built from source via the home-manager programs.anki
# module. anki needs qt6.qtwebengine, whose darwin build is broken upstream and
# only patched for 6.11.0 (see overlays/qtwebengine-darwin-fix). To keep those
# version-specific patches valid regardless of the system nixpkgs, anki is built
# from a frozen nixpkgs-anki input pinned at a qtwebengine 6.11.0 revision, with
# the fix overlay applied. Re-point the input and re-pin once the upstream
# darwin fix lands and a built qtwebengine is cached.
#
# The darwin package ships only a CLI bin/anki, so it is wrapped in an Anki.app
# bundle for home-manager to link into ~/Applications (Finder/Launchpad).
################################################################################
{ inputs, ... }:
{
  flake-file.inputs.nixpkgs-anki.url = "github:NixOS/nixpkgs/a0374025a863d007d98e3297f6aa46cc3141c2f0";

  flake.aspects.programs.anki.homeManager =
    { pkgs, config, ... }:
    let
      ankiPkgs = import inputs.nixpkgs-anki {
        inherit (pkgs.stdenv.hostPlatform) system;
        config.allowUnfree = true;
        overlays = [ inputs.self.lib.qtwebengineDarwinFixOverlay ];
      };

      ankiVersion = ankiPkgs.anki.version;

      # Loaded via PYTHONPATH from the launcher (below). On macOS, launching the
      # .app exec-chains into the Nix store (launcher -> bin/anki -> .anki-wrapped),
      # so the running executable lives outside the bundle and macOS re-delivers
      # the launch as a spurious FileOpen Apple Event for that executable. Anki
      # treats it as a file to import and rejects it with "Unsupported file type."
      # Drop FileOpen events that point at Anki's own program; real deck/add-on
      # opens still pass through.
      fileOpenFix = pkgs.writeText "sitecustomize.py" ''
        import os
        try:
            import aqt
            from aqt.qt import QEvent

            def _is_self(path):
                if not path or "/nix/store/" not in path:
                    return False
                base = os.path.basename(path)
                return (
                    path.endswith("/.anki-wrapped")
                    or path.endswith("/bin/anki")
                    or base.startswith(".anki-wrapped")
                )

            _orig_event = aqt.AnkiApp.event

            def event(self, evt):
                if (
                    evt is not None
                    and evt.type() == QEvent.Type.FileOpen
                    and _is_self(evt.file())
                ):
                    return True
                return _orig_event(self, evt)

            aqt.AnkiApp.event = event
        except Exception:
            pass
      '';

      # The home-manager module installs `package.withAddons [...]`, so the wrap
      # must survive that call: re-apply it to the addon-enabled result and carry
      # `withAddons` forward (below) so the module's assertion and call resolve.
      wrapWithApp =
        anki:
        (pkgs.symlinkJoin {
          name = "anki-with-app-${ankiVersion}";
          paths = [ anki ];
          nativeBuildInputs = [
            pkgs.libicns
            pkgs.makeBinaryWrapper
          ];
          postBuild = ''
            contents="$out/Applications/Anki.app/Contents"
            mkdir -p "$contents/MacOS" "$contents/Resources/fix"

            # No .icns in the package; build one from the bundled hicolor PNGs.
            png2icns "$contents/Resources/anki.icns" \
              ${ankiPkgs.anki}/share/icons/hicolor/32x32/apps/anki.png \
              ${ankiPkgs.anki}/share/icons/hicolor/128x128/apps/anki.png

            printf 'APPL????' > "$contents/PkgInfo"

            cat > "$contents/Info.plist" <<EOF
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
              <key>CFBundleExecutable</key><string>Anki</string>
              <key>CFBundleIconFile</key><string>anki</string>
              <key>CFBundleIdentifier</key><string>net.ankiweb.anki</string>
              <key>CFBundleName</key><string>Anki</string>
              <key>CFBundlePackageType</key><string>APPL</string>
              <key>CFBundleSignature</key><string>????</string>
              <key>CFBundleShortVersionString</key><string>${ankiVersion}</string>
              <key>NSHighResolutionCapable</key><true/>
            </dict>
            </plist>
            EOF

            cp ${fileOpenFix} "$contents/Resources/fix/sitecustomize.py"

            # A compiled launcher (not a shell script) as CFBundleExecutable, with
            # PYTHONPATH pointing at the FileOpen fix above.
            makeBinaryWrapper "$out/bin/anki" "$contents/MacOS/Anki" \
              --set PYTHONPATH "$contents/Resources/fix"
          '';
        })
        // {
          withAddons = addons: wrapWithApp (anki.withAddons addons);

          # symlinkJoin drops the wrapped package's nativeBuildInputs. The
          # module's ankiConfig helper scans `package.nativeBuildInputs` for the
          # isPy3 interpreter and, finding none, falls back to the system
          # `pkgs.anki` — whose qtwebengine is unpatched on darwin and fails to
          # build. Re-expose the frozen package's nativeBuildInputs so the helper
          # uses this package's python (and so the frozen 6.11.0) instead.
          inherit (anki) nativeBuildInputs;
        };
    in
    {
      sops.secrets = {
        anki-sync-username.sopsFile = ../../../secrets/shared/anki-sync.secret.yaml;
        anki-sync-key.sopsFile = ../../../secrets/shared/anki-sync.secret.yaml;
      };

      programs.anki = {
        enable = true;
        package = wrapWithApp ankiPkgs.anki;
        addons = [ ankiPkgs.ankiAddons.review-heatmap ];

        profiles."User 1" = {
          default = true;  
          sync = {
            usernameFile = config.sops.secrets.anki-sync-username.path;
            keyFile = config.sops.secrets.anki-sync-key.path;
            autoSync = true;
            syncMedia = true;
          };
        };
      };
    };
}
