# modules/system/cli-tools/darwin.nix
################################################################################
# CLI tools, developer utilities, and build infrastructure for darwin hosts.
################################################################################
{ inputs, ... }:
{
  flake.modules.darwin.cli-tools =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.darwin; [
        cachix
        remoteBuilders
        nix-nvim-overlay
        tartVm
        kitty
      ];

      environment.systemPackages = with pkgs; [
        nvim-pkg
        git
        unstable.claude-code
        gnupg
        gh
        unstable.bitwarden-cli
        unstable.tailscale
        eza
        qemu
      ];

      services.tailscale.enable = true;

      homebrew = {
        casks = [
          "bitwarden"
          "orbstack"
          "tailscale-app"
        ];
        brews = [ "ccat" ];
      };

      environment.variables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };
    };
}
