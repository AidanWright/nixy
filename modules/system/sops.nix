# modules/system/sops.nix
################################################################################
# Configures sops-nix for NixOS secrets management.
################################################################################
{ inputs, ... }:
{
  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.aspects.sops.nixos =
    { ... }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      # Derives the age decryption key from the host's SSH host key so no
      # separate key management is needed.
      sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };

  flake.aspects.sops.darwin =
    { pkgs, ... }:
    {
      imports = [ inputs.sops-nix.darwinModules.sops ];

      #sops.age.sshKeyPaths = [ "" ];
    };
}
