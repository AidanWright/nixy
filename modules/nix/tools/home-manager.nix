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

  flake.aspects.home-manager.darwin =
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
        # Move pre-existing files (e.g. a hand-made librewolf profiles.ini) aside
        # instead of aborting activation when home-manager wants to own them.
        backupFileExtension = "backup";
        users.${config.system.primaryUser}.home.stateVersion = "26.05";
      };
    };
}
