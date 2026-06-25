# modules/system/dev/desktop-tools.nix
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
      dev.desktop-tools = {
        includes = with aspects; [
          programs.kitty
        ];

        darwin =
          { pkgs, ... }:
          {
            environment.systemPackages = with pkgs; [
              unstable.bitwarden-cli
            ];

            # bitwarden stays on Homebrew: the nixpkgs bitwarden-desktop is pinned
            # to an EOL Electron, undesirable for a password manager.
            homebrew.casks = [
              "bitwarden"
              "orbstack"
            ];
          };
      };
    };
}
