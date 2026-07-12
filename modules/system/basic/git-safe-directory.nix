# modules/system/basic/git-safe-directory.nix
################################################################################
# Trust the nix-darwin config repo for every account on the host. Determinate
# Nix fetches the flake through libgit2, which refuses a repo whose directory
# owner differs from the fetching process. Once the daily user is demoted,
# rebuilds run as `admin` (and evaluation under `sudo` as root), neither of
# which owns the aidanwright-owned checkout. Mark it a `safe.directory` in the
# system gitconfig: it is HOME-independent, so libgit2's ownership check honors
# it no matter which account fetches. Both paths are listed because `/etc` is a
# symlink to `/private/etc` and the flake may be referenced either way.
################################################################################
{ ... }:
{
  flake.aspects.basic.git-safe-directory.darwin =
    { ... }:
    {
      environment.etc."gitconfig".text = ''
        [safe]
        	directory = /private/etc/nix-darwin
        	directory = /etc/nix-darwin
      '';
    };
}
