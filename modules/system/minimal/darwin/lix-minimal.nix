# modules/system/minimal/darwin/lix-minimal.nix
################################################################################
# Nix settings for darwin hosts using Lix. Mirrors determinate-minimal.nix
# but uses standard nix-darwin nix.* options instead of determinateNix.*.
################################################################################
{ ... }:
{
  flake.modules.darwin.lix-minimal =
    {
      config,
      lib,
      ...
    }:
    lib.mkIf config.nix.enable {
      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];

        extra-experimental-features = [
          "parallel-eval"
        ];

        warn-dirty = false;

        auto-optimise-store = true;

        max-jobs = "auto";

        sandbox = true;

        # 0 means use all available cores
        cores = 0;

        substituters = [
          # high priority since it's almost always used
          "https://cache.nixos.org?priority=10"
          "https://nix-community.cachix.org"
        ];

        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };

      nix.gc = {
        automatic = true;
        interval = {
          Hour = 3;
        };
      };

      nix.linux-builder.enable = true;
    };
}
