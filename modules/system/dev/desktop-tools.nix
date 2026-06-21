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
      desktop-tools = {
        includes = with aspects; [
          kitty
        ];

        darwin =
          { pkgs, ... }:
          {
            environment.systemPackages = with pkgs; [
              unstable.bitwarden-cli
            ];

            homebrew.casks = [
              "bitwarden"
              "orbstack"
            ];
          };
      };
    };
}
