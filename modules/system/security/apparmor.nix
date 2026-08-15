# modules/system/security/apparmor.nix
################################################################################
# https://gitlab.com/apparmor/apparmor/-/wikis/Documentation
# Mandatory access control: turns on AppArmor and supplies the shared pieces
# every service profile builds on. Profiles themselves live beside the service
# they confine and are constructed with `flake.lib.mkServiceProfile`.
#
# Inspect: aa-status
# Refine a profile: journalctl -b --since today --grep audit: | aa-logprof
#
# A complain-mode profile logs the rules it is missing as apparmor="ALLOWED";
# it never emits apparmor="DENIED", because it denies nothing. Grepping for
# DENIED while complaining therefore reports success no matter how incomplete
# the profile is. Read the right one for the state being used:
#   complain: journalctl -b --grep 'apparmor="ALLOWED"'
#   enforce:  journalctl -b --grep 'apparmor="DENIED"'
################################################################################
{ inputs, ... }:
{
  flake.aspects.security.apparmor.nixos =
    { lib, pkgs, ... }:
    {
      imports = [ inputs.self.modules.nixos."options.apparmor" ];

      security.apparmor.enable = true;

      # Upstream's own abstractions (base, nameservice, ssl_certs) and the
      # tunables every profile includes. Deliberately not roddhjav-apparmor-rules:
      # that package skips apparmor.d's preprocessor, so its 1500+ profiles still
      # resolve against FHS paths that do not exist here.
      security.apparmor.packages = [ pkgs.apparmor-profiles ];

      # Blanket read access to the store, which is world-readable and holds no
      # secrets. Only `r` is granted globally; map and execute stay with the
      # per-service closure rules, because it is the exec modifiers that produce
      # the conflicting-x-permission errors when applied to a store glob.
      security.apparmor.includes."local/nix-store" = ''
        /nix/store/ r,
        /nix/store/** r,
      '';

      # aa-logprof writes candidate profiles here, and the root is a tmpfs.
      persistentDirectories = [ "/var/cache/apparmor" ];

      # Left off deliberately: a cached policy is keyed by the store paths inside
      # it, so every rebuild would add another copy rather than replace one.
      security.apparmor.enableCache = false;

      # Recovery path for a profile that breaks a service needed to bring the
      # network up. Selecting it from the boot menu needs console access, which
      # a remote host does not have; from a reachable host use
      # `nixos-rebuild switch --specialisation no-apparmor` instead.
      specialisation.no-apparmor.configuration = {
        security.apparmor.enable = lib.mkForce false;
      };
    };
}
