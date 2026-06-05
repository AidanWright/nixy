# modules/system/virtualization/tart-base-image.nix
################################################################################
# Builds and pushes a Tart base image (Lix + nix-darwin) to an OCI registry.
# Apple Silicon only. Run once per nixpkgs series or when the base changes.
#
# Prerequisites:
#   Store a ghcr.io PAT in the macOS Keychain:
#     security add-generic-password -s ghcr.io -a <ghUsername> -w YOUR_PAT
#
# Build and push:
#   nix run --impure .#tart-base-image -- determinate
#   nix run --impure .#tart-base-image -- lix
#
# After pushing, trigger the 'Publish Base Image' workflow to make the package
# public. See .github/workflows/publish-base-image.yml.
################################################################################
{ config, lib, ... }:
{
  options.tartBaseImage = {
    baseImage = lib.mkOption {
      type = lib.types.str;
      default = "ghcr.io/cirruslabs/macos-tahoe-base:latest";
      description = "OCI image to clone when building the base. Must have the Tart Guest Agent installed.";
    };
    cores = lib.mkOption {
      type = lib.types.int;
      default = 4;
      description = "vCPU count during image build (must be a power of 2 for macOS guests).";
    };
    ramMb = lib.mkOption {
      type = lib.types.int;
      default = 8192;
      description = "RAM in MB during image build.";
    };
    diskGb = lib.mkOption {
      type = lib.types.int;
      default = 80;
      description = "Disk size in GB for the base image.";
    };
    registry = lib.mkOption {
      type = lib.types.str;
      default = "ghcr.io/AidanWright/nixy";
      description = "OCI registry to push the base image to.";
    };
    nixVersion = lib.mkOption {
      type = lib.types.str;
      default = "26.05";
      description = "nixpkgs/nix-darwin series used in the image name (e.g. base-26.05).";
    };
    repoUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://github.com/AidanWright/nixy";
      description = "Repository URL written into the org.opencontainers.image.source OCI label.";
    };
    ghUsername = lib.mkOption {
      type = lib.types.str;
      default = "AidanWright";
      description = "GitHub username for ghcr.io authentication (macOS Keychain lookup).";
    };
  };

  config.perSystem =
    { pkgs, system, ... }:
    lib.mkIf (system == "aarch64-darwin") {
      packages.tart-base-image =
        let
          cfg = config.tartBaseImage;
        in
        pkgs.writeShellApplication {
          name = "tart-base-image";
          runtimeInputs = [
            pkgs.unstable.tart
            pkgs.gnutar
            pkgs.crane
            pkgs.git
          ];
          text = ''
            NIX_VERSION="${cfg.nixVersion}"
            REGISTRY="${cfg.registry}"
            BASE_IMAGE="${cfg.baseImage}"
            REPO_URL="${cfg.repoUrl}"
            GH_USERNAME="${cfg.ghUsername}"
            CORES="${toString cfg.cores}"
            RAM_MB="${toString cfg.ramMb}"
            DISK_GB="${toString cfg.diskGb}"
            VARIANT="''${1:-}"

            VM_NAME="nixy-base-''${VARIANT}-''${NIX_VERSION}"
            IMAGE_NAME="base-''${VARIANT}-''${NIX_VERSION}"
            # OCI references must be lowercase; ghcr.io is case-insensitive.
            IMAGE_REPO="$(echo "''${REGISTRY}/''${IMAGE_NAME}" | tr '[:upper:]' '[:lower:]')"
            BUILD_VERSION="$(date -u +%Y.%m.%d-%H%M%S)"
            BUILD_CREATED="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

            exec_admin() { tart exec "$VM_NAME" sudo -u admin bash -c "$1"; }

            cleanup() { tart stop "$VM_NAME" 2>/dev/null || true; }
            trap cleanup EXIT

            info() { echo -e "\x1b[1;97;44m[INFO]\x1b[0m $1"; }
            error() { echo -e "\x1b[1;97;101m[ERROR]\x1b[0m $1"; }

            if [[ $VARIANT != "determinate" && $VARIANT != "lix" ]]; then
              error "Variant must be one of lix/determinate"
              exit 1
            fi

            if [[ -z "$(git ls-remote --tags https://github.com/NixOS/nixpkgs "$NIX_VERSION")" ]]; then
              error "Version $NIX_VERSION is not valid; must be one of: \
            $(git ls-remote --tags https://github.com/NixOS/nixpkgs \
                | awk '{print $2}' \
                | sed 's|refs/tags/||; s|\^{}$||' \
                | grep '^[0-9]' \
                | sort -u \
                | paste -sd ',' -)"
              exit 1
            fi

            if [ -d "$HOME/.tart/vms/$VM_NAME" ]; then
              info "Removing existing $VM_NAME ..."
              tart delete "$VM_NAME"
            fi

            info "Cloning ''${BASE_IMAGE} -> $VM_NAME ..."
            tart clone "''${BASE_IMAGE}" "$VM_NAME"
            tart set "$VM_NAME" \
              --cpu "''${CORES}" \
              --memory "''${RAM_MB}" \
              --disk-size "''${DISK_GB}"

            tart run "$VM_NAME" --no-graphics &
            TART_PID=$!

            # `tart ip --resolver agent` depends on the Tart Guest Agent's RPC,
            # which crash-loops on cold boot for several minutes. DHCP only needs
            # the VM on the network, which happens far earlier.
            info "Waiting for VM network..."
            tart ip "$VM_NAME" --wait 600 >/dev/null

            info "Waiting for VM guest agent..."
            deadline=$((SECONDS + 1800))
            until tart exec "$VM_NAME" true </dev/null >/dev/null 2>&1; do
              [ $SECONDS -ge $deadline ] && { error "VM guest agent timed out." >&2; exit 1; }
              sleep 5
            done

            info "Installing ''${VARIANT}..."
            if [ "$VARIANT" == "determinate" ]; then
              exec_admin "set -o pipefail; curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
                | sudo sh -s -- install --no-confirm 2>&1 \
                | sed -u 's/^/\x1b[0;38;5;254;48;5;236m[determinate-installer]\x1b[0m /'; \
                echo \$? > /tmp/.installer_exit"
            elif [ "$VARIANT" == "lix" ]; then
              exec_admin "set -o pipefail; curl -sSf -L https://install.lix.systems/lix \
                | sudo sh -s -- install --no-confirm 2>&1 \
                | sed -u 's/^/\x1b[0;38;5;254;48;5;236m[lix-installer]\x1b[0m /'; \
                echo \$? > /tmp/.installer_exit"
            else
              exit 1
            fi
            installer_exit=$(tart exec "$VM_NAME" cat /tmp/.installer_exit 2>/dev/null | tr -d '[:space:]')
            if [ "''${installer_exit:-1}" -ne 0 ]; then
              error "''${VARIANT} installer failed with exit code ''${installer_exit:-unknown}"
              exit 1
            fi

            info "Writing /etc/nix-darwin/flake.nix..."
            exec_admin "sudo mkdir -p /etc/nix-darwin && sudo chown admin:staff /etc/nix-darwin"
            exec_admin "sudo mv /etc/nix/nix.custom.conf /etc/nix/nix.custom.conf.before-nix-darwin || true"

            if [ "$VARIANT" == "determinate" ]; then
              tart exec -i "$VM_NAME" sudo -u admin bash -c "cat > /etc/nix-darwin/flake.nix" <<BASE_FLAKE
            {
              inputs = {
                nixpkgs.url = "github:NixOS/nixpkgs/nixos-$NIX_VERSION";
                determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
                nix-darwin = {
                  url = "github:nix-darwin/nix-darwin/nix-darwin-$NIX_VERSION";
                  inputs.nixpkgs.follows = "nixpkgs";
                };
              };
              outputs =
                inputs@{ nix-darwin, nixpkgs, ... }:
                {
                  darwinConfigurations.base = nix-darwin.lib.darwinSystem {
                    modules = [
                      inputs.determinate.darwinModules.default
                      {
                        nixpkgs.hostPlatform = "aarch64-darwin";
                        system.stateVersion = 6;
                        nix.enable = false;
                        determinateNix.enable = true;
                        environment.systemPackages = [
                          nix-darwin.packages.aarch64-darwin.darwin-rebuild
                          nix-darwin.packages.aarch64-darwin.darwin-version
                          nix-darwin.packages.aarch64-darwin.darwin-uninstaller
                          nixpkgs.legacyPackages.aarch64-darwin.fastfetch
                        ];
                      }
                    ];
                  };
                };
            }
            BASE_FLAKE
            elif [ "$VARIANT" == "lix" ]; then
              tart exec -i "$VM_NAME" sudo -u admin bash -c "cat > /etc/nix-darwin/flake.nix" <<BASE_FLAKE
            {
              inputs = {
                nixpkgs.url = "github:NixOS/nixpkgs/nixos-$NIX_VERSION";
                nix-darwin = {
                  url = "github:nix-darwin/nix-darwin/nix-darwin-$NIX_VERSION";
                  inputs.nixpkgs.follows = "nixpkgs";
                };
              };
              outputs =
                inputs@{ nix-darwin, nixpkgs, ... }:
                {
                  darwinConfigurations.base = nix-darwin.lib.darwinSystem {
                    modules = [
                      {
                        nixpkgs.hostPlatform = "aarch64-darwin";
                        system.stateVersion = 6;
                        nix.settings.experimental-features = "nix-command flakes";
                        environment.systemPackages = [
                          nix-darwin.packages.aarch64-darwin.darwin-rebuild
                          nix-darwin.packages.aarch64-darwin.darwin-version
                          nix-darwin.packages.aarch64-darwin.darwin-uninstaller
                          nixpkgs.legacyPackages.aarch64-darwin.fastfetch
                        ];
                      }
                    ];
                  };
                };
            }
            BASE_FLAKE
            fi

            info "Activating nix-darwin..."
            exec_admin "source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && cd /etc/nix-darwin && sudo nix run nix-darwin/nix-darwin-$NIX_VERSION#darwin-rebuild -- switch --flake .#base 2>&1 | sed -u 's/^/\x1b[0;38;5;254;48;5;236m[darwin-rebuild]\x1b[0m /'"

            exec_admin "echo"
            # need to source otherwise not on path
            exec_admin "source /etc/bashrc && fastfetch --bright-color true --pipe false"

            trap - EXIT
            info "Stopping VM..."
            tart stop "$VM_NAME"
            wait "$TART_PID" || true

            info "Logging into ghcr.io..."
            GH_TOKEN=$(security find-generic-password -s "ghcr.io" -a "''${GH_USERNAME}" -w 2>/dev/null || true)
            if [ -z "''${GH_TOKEN}" ]; then
              error "No ghcr.io token found in keychain. Store one with:" >&2
              echo "  security add-generic-password -s ghcr.io -a ''${GH_USERNAME} -w YOUR_PAT" >&2
              exit 1
            fi
            echo "''${GH_TOKEN}" | tart login ghcr.io --username "''${GH_USERNAME}" --password-stdin
            # crane uses its own credential store, so authenticate it separately.
            echo "''${GH_TOKEN}" | crane auth login ghcr.io --username "''${GH_USERNAME}" --password-stdin

            # `--chunk-size 3` enables ghcr.io's chunked-upload path (<4 MB per
            # chunk); the default monolithic upload times out on large blobs.
            info "Pushing ''${IMAGE_REPO}:''${BUILD_VERSION} (and :latest) ..."
            tart push \
              --chunk-size 3 \
              "$VM_NAME" \
              "''${IMAGE_REPO}:''${BUILD_VERSION}" \
              "''${IMAGE_REPO}:latest"

            # `tart push --label` does not write to the OCI manifest annotations
            # field that ghcr.io reads for repository linking. Use crane mutate
            # instead, which directly updates the manifest annotations map.
            annotate_image() {
              crane mutate \
                --annotation "org.opencontainers.image.source=''${REPO_URL}" \
                --annotation "org.opencontainers.image.url=''${REPO_URL}" \
                --annotation "org.opencontainers.image.title=nixy ''${IMAGE_NAME}" \
                --annotation "org.opencontainers.image.description=nixy base image for Nix ''${NIX_VERSION} on Darwin (aarch64)" \
                --annotation "org.opencontainers.image.version=''${BUILD_VERSION}" \
                --annotation "org.opencontainers.image.created=''${BUILD_CREATED}" \
                "$1"
            }
            info "Annotating ''${IMAGE_REPO}:''${BUILD_VERSION} ..."
            annotate_image "''${IMAGE_REPO}:''${BUILD_VERSION}"
            info "Annotating ''${IMAGE_REPO}:latest ..."
            annotate_image "''${IMAGE_REPO}:latest"

            info "Done. Base image available at:"
            echo "  ''${IMAGE_REPO}:''${BUILD_VERSION}"
            echo "  ''${IMAGE_REPO}:latest"
            echo ""
            echo "Run the 'Publish Base Image' GitHub Actions workflow to make the package public."
          '';
        };
    };
}
