# modules/nix/tools/remote-deploy.nix
################################################################################
# Exposes `provision` (nixos-anywhere) and `deploy` (nixos-rebuild) apps. Both
# take the flake host as their first argument and the SSH target (user@host,
# any user) as the second. Built for the machine running the command, so a
# Darwin deployer can install/update a Linux host. Run with --impure from the
# flake root.
#
# Initial provisioning — sops bootstrap:
#   Before provisioning, generate the host's SSH key and derive its age key so
#   sops secrets are decryptable on first boot.
#
#   1. Generate the host key:
#        install -d -m755 /tmp/biggy/etc/ssh
#        ssh-keygen -t ed25519 -N "" -f /tmp/biggy/etc/ssh/ssh_host_ed25519_key
#
#   2. Get the age key and add it to .sops.yaml:
#        ssh-to-age < /tmp/biggy/etc/ssh/ssh_host_ed25519_key.pub
#      Add the output as &biggy in .sops.yaml and re-encrypt any biggy secrets:
#        sops updatekeys modules/hosts/biggy/<secret>.yaml
#
#   3. Provision (the --extra-files flag injects the key before install).
#      First argument is the host, the rest pass through to nixos-anywhere:
#        nix run --impure .#provision -- biggy nixos@<ip> --extra-files /tmp/biggy
#
# Ongoing deploys (host, then SSH target):
#   nix run --impure .#deploy -- biggy nixos@biggy
################################################################################
{ inputs, lib, ... }:
{
  flake-file.inputs = {
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        disko.follows = "disko";
      };
    };
  };

  perSystem =
    { pkgs, ... }:
    {
      apps.provision.program = lib.getExe (
        pkgs.writeShellApplication {
          name = "provision";
          runtimeInputs = [ pkgs.nixos-anywhere ];
          text = ''
            hostname="$1"
            shift
            # pwd -P resolves symlinks; macOS /etc is a symlink and path: refs
            # reject symlinked components.
            nixos-anywhere --flake "path:$(pwd -P)#$hostname" "$@"
          '';
        }
      );

      apps.deploy.program = lib.getExe (
        pkgs.writeShellApplication {
          name = "deploy";
          runtimeInputs = [ pkgs.nixos-rebuild ];
          text = ''
            hostname="$1"
            target="$2"
            shift 2
            nixos-rebuild switch \
              --flake "path:$(pwd -P)#$hostname" \
              --target-host "$target" \
              --build-host "$target" \
              --use-remote-sudo "$@"
          '';
        }
      );
    };
}
