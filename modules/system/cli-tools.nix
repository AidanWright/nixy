# modules/system/cli-tools.nix
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
          kitty
        ];

        darwin =
          { pkgs, ... }:
          {
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
              unstable.sops
              unstable.age
              unstable.ssh-to-age
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

        nixos =
          { pkgs, ... }:
          {
            environment.systemPackages = with pkgs; [
              nvim-pkg
              git
              gnupg
              gh
            ];
          };
      };
    };
}
