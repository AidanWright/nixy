# modules/system/virtualization/tart-vm.nix
################################################################################
# Applies the current flake config to a VM cloned from the base image.
# Import this module in any darwin host that needs VM-based config testing.
#
# Prerequisites:
#   Build and push the base image first:
#     nix run --impure .#tart-base-image -- determinate
#     nix run --impure .#tart-base-image -- lix
#
# Run from the flake root (copies the working tree, including uncommitted changes):
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
      variant = if config.determinateNix.enable then "determinate" else "lix";
      imageRef = "${config.tart.registry}/base-${variant}-${config.tart.nixVersion}:latest";
      hostname = config.networking.hostName;
      cores = toString config.tart.cores;
      ramMb = toString config.tart.ramMb;
    in
    {
      options.tart = {
        registry = lib.mkOption {
          type = lib.types.str;
          default = "ghcr.io/aidanwright/nixy";
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
        name = "tart-vm-${hostname}";
        runtimeInputs = [
          pkgs.unstable.tart
          pkgs.sshpass
          pkgs.openssh
        ];
        text = ''
          VM_NAME="nixy-${hostname}-$$"

          info()  { echo -e "\x1b[1;97;44m[INFO]\x1b[0m $1"; }
          error() { echo -e "\x1b[1;97;101m[ERROR]\x1b[0m $1"; }

          cleanup() {
            info "Destroying VM..."
            tart stop "$VM_NAME" 2>/dev/null || true
            tart delete "$VM_NAME" 2>/dev/null || true
          }
          trap cleanup EXIT

          info "Cloning ${imageRef} -> $VM_NAME ..."
          tart clone "${imageRef}" "$VM_NAME"
          tart set "$VM_NAME" --cpu "${cores}" --memory "${ramMb}"

          tart run "$VM_NAME" --no-graphics &

          info "Waiting for VM network..."
          tart ip "$VM_NAME" --wait 600 >/dev/null

          info "Waiting for VM guest agent..."
          deadline=$((SECONDS + 1800))
          until tart exec "$VM_NAME" true </dev/null >/dev/null 2>&1; do
            [ $SECONDS -ge $deadline ] && { error "Guest agent timed out." >&2; exit 1; }
            sleep 5
          done

          VM_IP=$(tart ip "$VM_NAME")

          info "Starting nix-daemon..."
          # || true: bootstrap fails if already loaded, which is fine.
          tart exec "$VM_NAME" sudo launchctl bootstrap system \
            /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null || true
          tart exec "$VM_NAME" sudo launchctl kickstart -k \
            system/org.nixos.nix-daemon 2>/dev/null || true

          info "Waiting for nix-daemon..."
          deadline=$((SECONDS + 120))
          until tart exec "$VM_NAME" sudo /nix/var/nix/profiles/default/bin/nix \
              store ping </dev/null >/dev/null 2>&1; do
            [ $SECONDS -ge $deadline ] && { error "nix-daemon timed out." >&2; exit 1; }
            sleep 5
          done

          info "Copying flake to VM..."
          sshpass -p admin scp \
            -F /dev/null \
            -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            -r "$PWD" "admin@$VM_IP:/var/tmp/"

          BASENAME=$(basename "$PWD")

          info "Applying configuration..."
          tart exec "$VM_NAME" bash -c \
            "source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh \
            && sudo /run/current-system/sw/bin/darwin-rebuild switch \
                 --flake path:/var/tmp/$BASENAME#${hostname} 2>&1 \
            | sed -u 's/^/\x1b[0;38;5;254;48;5;236m[darwin-rebuild]\x1b[0m /'"
        '';
      };
    };
}
