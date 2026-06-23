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

  # Default account + home-manager wiring for the primary user; mkDefault so a
  # per-user module under modules/users/ can override it.
  flake.aspects.home-manager.darwin =
    {
      config,
      lib,
      ...
    }:
    {
      imports = [ inputs.home-manager.darwinModules.home-manager ];

      users.users.${config.system.primaryUser} = {
        name = lib.mkDefault config.system.primaryUser;
        home = lib.mkDefault "/Users/${config.system.primaryUser}";
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        # Move pre-existing files (e.g. a hand-made librewolf profiles.ini) aside
        # instead of aborting activation when home-manager wants to own them.
        backupFileExtension = "backup";
        users.${config.system.primaryUser}.home.stateVersion = lib.mkDefault "26.05";
      };
    };
}
