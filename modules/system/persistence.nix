# modules/system/persistence.nix
################################################################################
# https://github.com/nix-community/impermanence
# Aggregator options (`persistentDirectories`, `persistentFiles`) that services
# use to declare paths to survive a reboot; the impermanence aspect consumes
# them so services remain unaware of whether impermanence is active.
################################################################################
{ ... }:
{
  flake.aspects.persistence.nixos =
    { lib, ... }:
    {
      options.persistentDirectories = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Directories to persist across reboots via the impermanence module.";
      };

      options.persistentFiles = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Files to persist across reboots via the impermanence module.";
      };
    };
}
