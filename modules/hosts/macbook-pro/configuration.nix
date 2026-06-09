# modules/hosts/macbook-pro/configuration.nix
################################################################################
# Imports all system modules for the macbook darwin host.
################################################################################
{
  inputs,
  ...
}:
{
  flake.modules.darwin.macbook-pro =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.darwin; [
        determinate
        tartVm
        nix-nvim-overlay
        homebrew
        remoteBuilders
        cachix
        spicetify
        zoho
      ];
      networking.hostName = "macbook-pro";
      system.primaryUser = "aidanwright";

      environment.systemPackages = with pkgs; [
        nvim-pkg # The default package added by the overlay
        git
        claude-code
        gnupg
        gh
        unstable.bitwarden-cli
        unstable.librewolf
        rectangle
        tailscale
        #unstable.kitty
        #unstable.kitty-themes
        eza
        qemu
      ];

      services.tailscale.enable = true;

      homebrew.casks = [
        "bitwarden"
        "orbstack"
        "tailscale-app"
        "qspace-pro"
      ];

      homebrew.brews = [
        "ccat"
      ];

      homebrew.masApps = {
        "Airmail" = 918858936;
      };

      environment.variables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };
    };
}
