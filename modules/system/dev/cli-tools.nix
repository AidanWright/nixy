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
      cli-tools = {
        includes = with aspects; [
          cachix
          remote-builders
          nix-nvim-overlay
          tart-vm
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
              unstable.claude-code
              eza
              qemu
            ];

            homebrew.brews = [ "ccat" ];

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
