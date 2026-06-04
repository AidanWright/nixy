# modules/system/determinate.nix
################################################################################
# Enables Determinate Nix for darwin and NixOS configurations.
# See: https://docs.determinate.systems/guides/nix-darwin/
# See: https://docs.determinate.systems/guides/advanced-installation/#nixos
################################################################################
{ inputs, ... }:
{
  flake-file.inputs.determinate = {
    url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.nix.inputs.nixpkgs.follows = "determinate/nixpkgs";
    inputs.nix.inputs.flake-parts.follows = "flake-parts";
  };

  flake.modules.darwin.determinate =
    { ... }:
    {
      imports = [ inputs.determinate.darwinModules.default ];
      nix.enable = false;
      determinateNix.enable = true;
    };

  flake.modules.nixos.determinate =
    { ... }:
    {
      imports = [ inputs.determinate.nixosModules.default ];
      nix.settings.substituters = [ "https://install.determinate.systems" ];
      nix.settings.trusted-public-keys = [
        "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      ];
    };
}
