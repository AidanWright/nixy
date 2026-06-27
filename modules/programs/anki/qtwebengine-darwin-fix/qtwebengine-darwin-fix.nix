# modules/nix/overlays/qtwebengine-darwin-fix/qtwebengine-darwin-fix.nix
################################################################################
# Exposes flake.lib.qtwebengineDarwinFixOverlay: an overlay that fixes the
# qt6.qtwebengine 6.11.0 build on aarch64-darwin so anki builds from source.
# It is applied to the frozen nixpkgs-anki input (see programs/anki.nix), not
# the system nixpkgs, because the patches are version-specific to 6.11.0.
# Two unrelated upstream breakages are worked around:
#   1. NixOS/nixpkgs PR #515997 (unmerged): chromium's in-tree clang cannot find
#      the libc++ headers and emits a relative -isysroot, so QtWebEngineCore
#      fails to compile. See issue #514179.
#   2. nodejs 24.15.0 has an EBADF regression that crashes @rollup/wasm-node
#      during the devtools-frontend bundling; build with nodejs_22 instead.
################################################################################
{ ... }:
let
  patchQtwebengine =
    nodejs: qtwebengine:
    (qtwebengine.override { inherit nodejs; }).overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        ./clang-base-path-from-cmake-compiler.patch
        ./lflags-remove-strip-darwin-isysroot.patch
      ];

      # PR bumps the deployment target to 12.0: chromium 6.11 uses
      # kIOMainPortDefault, which is unavailable before macOS 12.
      cmakeFlags = map (
        flag:
        if flag == "-DCMAKE_OSX_DEPLOYMENT_TARGET=11.0" then "-DCMAKE_OSX_DEPLOYMENT_TARGET=12.0" else flag
      ) (old.cmakeFlags or [ ]);
    });

  # overrideScope drops the scope's own `.override`, but python-packages.nix
  # rebuilds qt6 with `pkgs.qt6.override { python3 = ...; }` (the variant
  # pyqt6-webengine uses). Re-attach an `.override` that re-applies the fix so
  # that path stays patched and does not fail with "attribute 'override' missing".
  withQtwebengineFix =
    nodejs: qt6:
    (qt6.overrideScope (_: qtPrev: { qtwebengine = patchQtwebengine nodejs qtPrev.qtwebengine; }))
    // {
      override = args: withQtwebengineFix nodejs (qt6.override args);
    };

  overlay = final: prev: {
    qt6 = withQtwebengineFix final.nodejs_22 prev.qt6;
  };
in
{
  flake.lib.qtwebengineDarwinFixOverlay = overlay;
}
