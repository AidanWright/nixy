# modules/nix/tools/home-manager.nix
################################################################################
#
################################################################################
{ inputs, ... }:
{
  flake-file.inputs.home-manager = {
    url = "github:nix-community/home-manager/release-26.05";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.darwin.home-manager =
    { config, ... }:
    {
      imports = [ inputs.home-manager.darwinModules.home-manager ];

      users.users.${config.system.primaryUser} = {
        name = config.system.primaryUser;
        home = "/Users/${config.system.primaryUser}";
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${config.system.primaryUser}.home.stateVersion = "26.05";
      };
    };
}
