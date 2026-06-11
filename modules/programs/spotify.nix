# modules/programs/spotify.nix
################################################################################
# Extends Spotify with custom themes and extensions via Spicetify.
################################################################################
{ inputs, ... }:
{
  flake-file.inputs.spicetify-nix = {
    url = "github:Gerg-L/spicetify-nix";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
    inputs.systems.follows = "systems";
  };

  flake.modules.darwin.spotify =
    { pkgs, ... }:
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      imports = [ inputs.spicetify-nix.darwinModules.spicetify ];
      programs.spicetify = {
        enable = true;
        enabledExtensions = with spicePkgs.extensions; [
          adblockify
          hidePodcasts
          history
          shuffle
          queueTime
          {
            src =
              (pkgs.fetchFromGitHub {
                owner = "ohitstom";
                repo = "spicetify-extensions";
                rev = "f1cc1b2aaa27f0f822da88dda6d339c4c80fcbbd";
                hash = "sha256-RvKzS+9ZraWY+c1wKUEIPTn3Ks4gWj56eqbbOpzUMk0=";
              })
              + /pixelatedImages;
            name = "pixelatedImages.js";
          }
        ];
        enabledCustomApps = with spicePkgs.apps; [
          historyInSidebar
          #marketplace
        ];
        theme = {
          name = "tui";
          src =
            (pkgs.fetchFromGitHub {
              owner = "spicetify";
              repo = "spicetify-themes";
              rev = "26e77f560d9eed3edc0f89c4304520d579631d54";
              hash = "sha256-jEBkyzCjcN6eUZ/RLmxRIPlrL1PEvKGOr/9auQOsqPg=";
            })
            + /text;
          additionalCss = ''
            .view-homeShortcutsGrid-shortcuts::before {
              content: "────█▀█▄▄▄▄─────██▄\A────█▀▄▄▄▄█─────█▀▀█\A─▄▄▄█─────█──▄▄▄█\A██▀▄█─▄██▀█─███▀█\A─▀▀▀──▀█▄█▀─▀█▄█▀\A";
            }
          '';
        };
        #theme = spicePkgs.themes.text;
        colorScheme = "Gruvbox";
      };
    };
}
