# modules/system/virtualization/tart-vm.nix
################################################################################
# Applies the current flake config to a VM from the base image using Cirrus CLI.
# Import this module in any darwin host that needs VM-based config testing.
#
# Prerequisites:
#   Build and push the base image first:
#     nix run --impure .#tart-base-image
#   Commit or stage any changes (cirrus run uploads committed+staged files).
#
# Run:
#   nix run --impure .#darwinConfigurations.<hostname>.config.system.build.tart-vm
################################################################################
{ ... }:
{
  flake.modules.darwin.tartVm =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      imageRef = "${config.tart.registry}/base-${config.tart.nixVersion}:latest";
      cirrusConfig = pkgs.replaceVars ./cirrus.yml {
        inherit imageRef;
        cores = toString config.tart.cores;
        memoryMb = toString config.tart.ramMb;
        hostname = config.networking.hostName;
      };
    in
    {
      options.tart = {
        registry = lib.mkOption {
          type = lib.types.str;
          default = "ghcr.io/AidanWright/nixy";
          description = "OCI registry where the base image is stored.";
        };
        nixVersion = lib.mkOption {
          type = lib.types.str;
          default = "26.05";
          description = "nixpkgs/nix-darwin series used in the base image name (e.g. base-26.05).";
        };
        cores = lib.mkOption {
          type = lib.types.int;
          default = 4;
          description = "vCPU count for the test VM (must be a power of 2 for macOS guests).";
        };
        ramMb = lib.mkOption {
          type = lib.types.int;
          default = 8192;
          description = "RAM in MB for the test VM.";
        };
      };

      config.system.build.tart-vm = pkgs.writeShellApplication {
        name = "tart-vm-${config.networking.hostName}";
        runtimeInputs = [ pkgs.cirrus-cli ];
        text = ''
          CIRRUS_YML="$PWD/.cirrus.yml"
          if [ -f "$CIRRUS_YML" ]; then
            echo "Error: $CIRRUS_YML already exists — remove or rename it first." >&2
            exit 1
          fi
          trap 'rm -f "$CIRRUS_YML"' EXIT

          cp ${cirrusConfig} "$CIRRUS_YML"
          cirrus run "darwin-rebuild"
        '';
      };
    };
}
