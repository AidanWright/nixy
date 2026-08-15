# modules/system/options/apparmor.nix
################################################################################
# Aggregator option (`apparmorDefaultState`) that service profiles read so the
# enforcement posture of the whole host moves in one place, while any single
# service can still be promoted ahead of the rest by overriding its own state.
################################################################################
{ ... }:
{
  flake.aspects.options.apparmor.nixos =
    { lib, ... }:
    {
      options.apparmorDefaultState = lib.mkOption {
        type = lib.types.enum [
          "disable"
          "complain"
          "enforce"
        ];
        # Complain logs denials without blocking them. Enforcing a profile that
        # has never been observed can stop a service from starting, so a profile
        # is only promoted after its audit log comes back clean.
        default = "complain";
        description = "Enforcement state applied to service profiles that do not set their own.";
      };
    };
}
