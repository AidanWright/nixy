# modules/system/basic/darwin/stylix.nix
################################################################################
# System-wide theming: colour scheme, wallpaper, and fonts.
################################################################################
{ inputs, ... }:
{
  flake-file.inputs.stylix = {
    url = "github:danth/stylix/release-26.05";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.darwin.stylix =
    { pkgs, lib, ... }:
    {
      imports = [ inputs.stylix.darwinModules.stylix ];

      stylix = {
        enable = true;
        # photography/gruvbox-forest.jpg photography/jakub-sejkora-utqJcneoFjo.jpg photography/flowers-2.jpg
        # photography/cactus.png painting/View_of_Vent_in_the_Ventertal.jpg minimalistic/war-in-space.png
        # minimalistic/gruv-abstract-maze.png minimalistic/FreshCake_computerFiles.jpg
        image = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/AngelJumbo/gruvbox-wallpapers/main/wallpapers/photography/houseonthesideofalake.jpg";
          hash = "sha256-obKI4qZvucogqRCl51lwV9X8SRaMqcbBwWMfc9TupIo=";
        };
        base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
        fonts = {
          monospace = {
            package = pkgs.nerd-fonts.jetbrains-mono;
            name = "JetBrainsMono Nerd Font Mono";
          };
          sansSerif = {
            package = pkgs.inter;
            name = "Inter";
          };
          serif = {
            package = pkgs.inter;
            name = "Inter";
          };
          sizes = {
            terminal = 14;
            applications = 12;
          };
        };
      };
    };
}
