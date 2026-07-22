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
          { config, pkgs, ... }:
          {
            environment.systemPackages = with pkgs; [
              unstable.bitwarden-cli
              unar
            ];

            # bitwarden stays on Homebrew: the nixpkgs bitwarden-desktop is pinned
            # to an EOL Electron, undesirable for a password manager.
            homebrew.casks = [
              "bitwarden"
              "orbstack"
            ];

            homebrew.masApps."Yubico Authenticator" = 1497506650;

            home-manager.users.${config.system.primaryUser} =
              { config, ... }:
              {
                home.sessionVariables.SSH_AUTH_SOCK = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";
              };
          };
      };
    };
}
