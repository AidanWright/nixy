# modules/programs/anki.nix
################################################################################
# Anki flashcard app, built from source via the home-manager programs.anki
# module. This depends on qt6.qtwebengine, whose darwin build is patched by the
# overlays.qtwebengine-darwin-fix aspect (NixOS/nixpkgs PR #515997). Without
# that overlay the source build fails; see issue #514179.
################################################################################
{ inputs, ... }:
{
  flake.aspects.programs.anki = {
    homeManager = _: {
      programs.anki.enable = true;
    };

    # qtwebengine's darwin build is broken upstream; the overlay must apply at
    # the system nixpkgs layer (home-manager.useGlobalPkgs reuses system pkgs),
    # so the dependency is imported here rather than in the homeManager class.
    darwin = _: {
      imports = [ inputs.self.modules.darwin."overlays.qtwebengine-darwin-fix" ];
    };
  };
}
