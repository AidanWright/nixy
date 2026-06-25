# modules/system/dev/cli-tools.nix
################################################################################
# CLI tools, developer utilities, and build infrastructure for all hosts.
################################################################################
{ ... }:
{
  flake.aspects =
    {
      aspects,
      ...
    }:
    {
      dev.cli-tools = {
        includes = with aspects; [
          dev.cachix
          dev.remote-builders
          overlays.nvim
          virt.tart-vm
        ];

        darwin =
          { pkgs, ... }:
          {
            environment.systemPackages = with pkgs; [
              ### essentials
              nvim-pkg
              ripgrep
              git
              gnupg
              gh

              ### nice to have
              eza
              qemu
            ];

            environment.variables = {
              EDITOR = "nvim";
              VISUAL = "nvim";
            };
          };

        nixos =
          { pkgs, ... }:
          {
            environment.systemPackages = with pkgs; [
              ### essentials
              nvim-pkg
              git
              gnupg
              gh
            ];

            environment.variables = {
              EDITOR = "nvim";
              VISUAL = "nvim";
            };
          };
      };
    };
}
