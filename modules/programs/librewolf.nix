# modules/programs/librewolf.nix
################################################################################
# Configures the LibreWolf browser and a hardened default profile via home-manager.
# Declarative add-ons are pulled from the NUR `rycee.firefox-addons` set.
################################################################################
{ inputs, ... }:
{
  flake-file.inputs.nur = {
    url = "github:nix-community/NUR";
    inputs.nixpkgs.follows = "nixpkgs";
    # Without this, NUR pulls its own (identical) flake-parts node, which
    # nix-auto-follow collapses but nix re-expands — breaking check-flake-file.
    inputs.flake-parts.follows = "flake-parts";
  };

  flake.aspects.librewolf.darwin =
    {
      config,
      pkgs,
      ...
    }:
    let
      firefoxAddons =
        inputs.nur.legacyPackages.${pkgs.stdenv.hostPlatform.system}.repos.rycee.firefox-addons;
    in
    {
      home-manager.users.${config.system.primaryUser} = {
        programs.librewolf = {
          enable = true;

          settings = {
            "browser.startup.homepage" = "about:home";
            "privacy.donottrackheader.enabled" = true;
            "privacy.resistFingerprinting" = true;
          };

          profiles.default = {
            id = 0;
            isDefault = true;

            settings = {
              "browser.toolbars.bookmarks.visibility" = "always";
            };

            search = {
              force = true;
              default = "ddg";
            };

            extensions.packages = with firefoxAddons; [
              ublock-origin
              bitwarden
            ];
          };
        };
      };
    };
}
