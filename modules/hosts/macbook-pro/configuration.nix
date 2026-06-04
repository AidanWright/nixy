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
      ];
      networking.hostName = "macbook-pro";

      environment.systemPackages = with pkgs; [
        nvim-pkg # The default package added by the overlay
        git
        claude-code
      ];

      environment.variables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };
    };
}
