# modules/nix/overlays/darwin-apps.nix
################################################################################
# Packages prebuilt macOS .app bundles from their official releases as
# pkgs.darwinApps.*, replacing the equivalent Homebrew casks. To update one:
# bump version + url, set its hash to lib.fakeHash, rebuild, paste the real hash.
################################################################################
{ ... }:
let
  overlay = final: _prev: {
    darwinApps =
      let
        mkMacosApp =
          {
            pname,
            version,
            src,
            app,
            archive ? "dmg",
          }:
          final.stdenvNoCC.mkDerivation {
            inherit pname version src;

            nativeBuildInputs = [ (if archive == "dmg" then final.undmg else final.unzip) ];

            sourceRoot = ".";
            unpackPhase = ''
              runHook preUnpack
              ${if archive == "dmg" then ''undmg "$src"'' else ''unzip -q "$src"''}
              runHook postUnpack
            '';

            installPhase = ''
              runHook preInstall
              mkdir -p "$out/Applications"
              cp -R "${app}" "$out/Applications/"
              runHook postInstall
            '';

            # Prebuilt, signed bundles: don't let nix rewrite or strip them.
            dontFixup = true;
          };
      in
      {
        claude-desktop = mkMacosApp {
          pname = "claude-desktop";
          version = "1.15962.0";
          app = "Claude.app";
          archive = "zip";
          src = final.fetchurl {
            url = "https://downloads.claude.ai/releases/darwin/universal/1.15962.0/Claude-039543c96f820be3f47c6a5bcdb32d7278724ef1.zip";
            hash = "sha256-f6+rFlzfZoNK8kODal+YSVvphfymR7tzLIfA+cma4ZU=";
          };
        };

        dockdoor = mkMacosApp {
          pname = "dockdoor";
          version = "1.39.3";
          app = "DockDoor.app";
          src = final.fetchurl {
            url = "https://github.com/ejbills/DockDoor/releases/download/1.39.3/DockDoor.dmg";
            hash = "sha256-/iglm5eN82r4yVCZ5bh11Arc6j3UF588wrZ8vSrIarQ=";
          };
        };

        cryptomator = mkMacosApp {
          pname = "cryptomator";
          version = "1.19.2";
          app = "Cryptomator.app";
          src = final.fetchurl {
            url = "https://github.com/cryptomator/cryptomator/releases/download/1.19.2/Cryptomator-1.19.2-arm64.dmg";
            hash = "sha256-6Xii2lRdiqyhGS+vba30xRvfXpvcIyoidhhAHAuDP5o=";
          };
        };
      };
  };
in
{
  flake.aspects.overlays.darwin-apps.darwin = _: {
    nixpkgs.overlays = [ overlay ];
  };
}
