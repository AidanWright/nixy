# modules/system/security/sops.nix
################################################################################
# Configures sops-nix for NixOS secrets management.
#
# Also assembles ~/.config/sops/age/keys.txt for every home-manager user, so the
# `sops` CLI can decrypt with whichever identity a file was encrypted to: the
# host key, the user's own key, or the YubiKey.
################################################################################
{ inputs, lib, ... }:
let
  hostIdentityKey = "/etc/ssh/ssh_host_ed25519_key";

  yubikeyIdentities = [ "AGE-PLUGIN-YUBIKEY-1J4ZY2Q5Z4J6RFSGK84X3U" ];

  mkCliIdentityCollector =
    pkgs:
    pkgs.writeShellApplication {
      name = "sops-collect-age-identities";
      runtimeInputs = with pkgs; [
        coreutils
        unstable.ssh-to-age
      ];
      text = ''
        home=$1
        owner=$2
        group=$(id -gn "$owner")

        install -d -m 700 -o "$owner" -g "$group" "$home/.config/sops/age"

        identities=$(mktemp)
        trap 'rm -f "$identities"' EXIT
        chmod 600 "$identities"

        if [ -r "${hostIdentityKey}" ]; then
          ssh-to-age -private-key -i "${hostIdentityKey}" >> "$identities"
        fi

        if [ -r "$home/.config/sops/age/hm-key.txt" ]; then
          cat "$home/.config/sops/age/hm-key.txt" >> "$identities"
        fi

        printf '%s\n' ${lib.escapeShellArgs yubikeyIdentities} >> "$identities"

        install -m 600 -o "$owner" -g "$group" "$identities" "$home/.config/sops/age/keys.txt"
      '';
    };
in
{
  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.aspects.security.sops.nixos =
    { pkgs, ... }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      environment.systemPackages = with pkgs; [
        unstable.sops
        unstable.age
        unstable.ssh-to-age
        unstable.gnupg
        unstable.ssh-to-pgp
      ];

      sops.age.sshKeyPaths = [ hostIdentityKey ];

      persistentFiles = [ hostIdentityKey ];
      services.openssh.generateHostKeys = true;
    };

  flake.aspects.security.sops.darwin =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      collectIdentities = mkCliIdentityCollector pkgs;

      collectFor =
        user:
        "${lib.getExe collectIdentities} "
        + "${lib.escapeShellArg config.home-manager.users.${user}.home.homeDirectory} "
        + lib.escapeShellArg user;
    in
    {
      imports = [ inputs.sops-nix.darwinModules.sops ];

      environment.systemPackages = with pkgs; [
        unstable.sops
        unstable.age
        unstable.ssh-to-age
        unstable.gnupg
        unstable.ssh-to-pgp
        unstable.age-plugin-yubikey
      ];

      sops.age.sshKeyPaths = [ hostIdentityKey ];

      system.activationScripts.postActivation.text = lib.mkAfter (
        lib.concatMapStringsSep "\n" collectFor (lib.attrNames config.home-manager.users)
      );
    };

  # Home-manager secrets decrypt at login with a disposable per-user age key
  # (generated on first activation); its public half is a recipient in
  # .sops.yaml. The YubiKey stays the author/recovery key. Wired for every user
  # via home-manager.sharedModules in flake-parts/lib.nix.
  flake.aspects.security.sops.homeManager =
    { config, ... }:
    {
      imports = [ inputs.sops-nix.homeManagerModules.sops ];

      sops.age = {
        keyFile = "${config.home.homeDirectory}/.config/sops/age/hm-key.txt";
        generateKey = true;
      };

      home.sessionVariables.SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    };
}
