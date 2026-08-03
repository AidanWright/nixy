# modules/users/aidanwright/homeManager.nix
################################################################################
# Shared cross-platform home-manager config for aidanwright. Consumed both by
# the darwin host (home-manager.users.aidanwright imports it) and by the
# standalone WSL home (flake-parts.nix -> mkHomeManager). Only platform-neutral
# settings live here so it stays buildable on Linux; darwin-only home settings
# (dock, macOS apps) stay in darwin.nix.
################################################################################
{ ... }:
{
  flake.aspects =
    { aspects, ... }:
    {
      aidanwright = {
        includes = with aspects; [
          programs.claude
          programs.git
          programs.gpg
          programs.fish
          programs.eza
          programs.bat
          programs.starship
        ];

        homeManager =
          {
            pkgs,
            lib,
            config,
            ...
          }:
          {
            home.username = lib.mkDefault "aidanwright";
            # mkDefault so nix-darwin's home-manager integration (which derives
            # these from the user record) wins there; the standalone Linux home
            # has no such integration and falls back to these.
            home.homeDirectory = lib.mkDefault (
              if pkgs.stdenv.hostPlatform.isDarwin then "/Users/aidanwright" else "/home/aidanwright"
            );
            home.stateVersion = lib.mkDefault "26.05";

            home.sessionVariables.SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

            # Signing key + identity are user-specific, so they live here rather
            # than in the shared programs.git aspect (which only enables git).
            programs.git = {
              settings.user = {
                name = "Aidan Wright";
                email = "38870143+AidanWright@users.noreply.github.com";
              };
              signing = {
                # mkDefault so a host with its own card (e.g. the WSL box's
                # YubiKey) can point signing at that key instead.
                key = lib.mkDefault "1810A874AD3037F1";
                format = "openpgp";
                signByDefault = true;
              };
            };
          };
      };
    };
}
