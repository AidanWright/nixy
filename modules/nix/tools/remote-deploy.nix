################################################################################
# modules/nix/tools/remote-deploy.nix
################################################################################
# Exposes system.build.provision (nixos-anywhere) and system.build.deploy
# (nixos-rebuild) for every NixOS host. Run with --impure from the flake root.
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
#   3. Provision (the --extra-files flag injects the key before install):
#        nix run --impure .#nixosConfigurations.<host>.config.system.build.provision \
#          -- root@<ip> --extra-files /tmp/biggy
#
# Ongoing deploys:
#   nix run --impure .#nixosConfigurations.<host>.config.system.build.deploy
################################################################################
{ ... }:
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

  flake.aspects.remote-deploy.nixos =
    { config, pkgs, ... }:
    let
      hostname = config.networking.hostName;
    in
    {
      system.build.provision = pkgs.pkgsBuildHost.writeShellApplication {
        name = "provision-${hostname}";
        runtimeInputs = [ pkgs.pkgsBuildHost.nixos-anywhere ];
        text = ''
          nixos-anywhere --flake "path:$PWD#${hostname}" "$@"
        '';
      };

      system.build.deploy = pkgs.pkgsBuildHost.writeShellApplication {
        name = "deploy-${hostname}";
        runtimeInputs = [ pkgs.pkgsBuildHost.nixos-rebuild ];
        text = ''
          nixos-rebuild switch \
            --flake "path:$PWD#${hostname}" \
            --target-host "root@${hostname}" \
            --build-host "root@${hostname}" \
            --use-remote-sudo
        '';
      };
    };
}
