# modules/system/minimal/determinate-minimal.nix
################################################################################
# Nix settings for darwin hosts using Determinate Nix. Imported by system-minimal
# when determinateNix.enable = true
################################################################################
{ ... }:
{
  flake.aspects.minimal.determinate.darwin =
    {
      config,
      lib,
      ...
    }:
    lib.mkIf config.determinateNix.enable {
      # Custom settings written to /etc/nix/nix.custom.conf
      determinateNix = {
        customSettings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];

          # avoids copying (potentially large) source trees unnecessarily.
          lazy-trees = true;

          warn-dirty = false;

          # Nix automatically detects files in the store that have identical contents, and replaces them with hard links to a single copy. This saves disk space.
          auto-optimise-store = true;

          # causes Nix to use the number of CPUs in your system
          max-jobs = "auto";

          # Builds are isolated from the normal file system hierarchy and only see their dependencies in the Nix store, the temporary build directory
          # The use of a sandbox requires that Nix is run as root (so you should use the "build users" feature to perform the actual builds under different users than root)
          sandbox = true;

          # Enables parallel evaluation (remove this setting or set the value to 1 to disable)
          eval-cores = 0;

          extra-experimental-features = [
            "build-time-fetch-tree" # Enables build-time flake inputs
            "parallel-eval" # Enables parallel evaluation
            "wasm-builtin"
          ];
          substituters = [
            # high priority since it's almost always used
            "https://cache.nixos.org?priority=10"
            "https://install.determinate.systems"
            "https://nix-community.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM"
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];

          ### Opinionated settings below:

          # Disables the use of the flake registry on GitHub.
          # Means the system won’t pull from the global registry but means you have to maintain your own,
          # makes it harder to discover new flakes etc.
          #
          # flake-registry = "";
        };

        determinateNixd = {
          garbageCollector.strategy = "automatic";

          # enable native Linux builder
          builder.state = "enabled";

          #telemetry.sentry.endpoint = null;
        };
      };
    };
}
