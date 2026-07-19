# modules/system/security/sops.nix
################################################################################
# Configures sops-nix for NixOS secrets management.
################################################################################
{ inputs, ... }:
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

      # Derives the age decryption key from the host's SSH host key so no
      # separate key management is needed.
      sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };

  flake.aspects.security.sops.darwin =
    { pkgs, ... }:
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

      sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
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
    };
}
