# modules/system/cli-tools/nixos.nix
################################################################################
# CLI tools for NixOS hosts.
################################################################################
{ inputs, ... }:
{
  flake.modules.nixos.cli-tools =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        cachix
        remoteBuilders
        nix-nvim-overlay
      ];

      environment.systemPackages = with pkgs; [
        nvim-pkg
        git
        gnupg
        gh
        eza
      ];
    };
}
