# modules/nix/tools/nix-fast-build.nix
################################################################################
# Exposes nix-fast-build from this flake's locked nixpkgs, so CI evaluates with
# a pinned toolchain instead of whatever `nix run nixpkgs#...` resolves to.
#
# Run: nix run .#nix-fast-build -- --flake .#checks.<system>
################################################################################
{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.nix-fast-build = pkgs.nix-fast-build;
    };
}
