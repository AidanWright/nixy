# modules/nix/flake-parts/lib.nix
################################################################################
# https://github.com/Doc-Steve/dendritic-design-with-flake-parts/blob/main/modules/nix/flake-parts%20%5B%5D/lib.nix#L25
################################################################################
{
  inputs,
  lib,
  ...
}:
{
  # Helper functions for creating system / home-manager configurations

  options.flake.lib = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = { };
  };

  config.flake.lib = {

    mkNixos = system: name: {
      ${name} = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          inputs.self.modules.nixos.${name}
          inputs.self.modules.nixos.unstable-overlay
          { nixpkgs.hostPlatform = lib.mkDefault system; }
        ];
      };
    };

    mkDarwin = system: name: {
      ${name} = inputs.nix-darwin.lib.darwinSystem {
        modules = [
          inputs.self.modules.darwin.${name}
          inputs.self.modules.darwin.unstable-overlay
          {
            nixpkgs.hostPlatform = lib.mkDefault system;
            system.stateVersion = lib.mkDefault 6;
          }
        ];
      };
    };

    mkHomeManager = system: name: {
      ${name} = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        modules = [
          inputs.self.modules.homeManager.${name}
          { nixpkgs.config.allowUnfree = true; }
        ];
      };
    };

  };
}
