# modules/nix/flake-parts/lib.nix
################################################################################
# Exports mkNixos, mkDarwin, and mkHomeManager helpers via flake.lib.
# https://github.com/Doc-Steve/dendritic-design-with-flake-parts/blob/main/modules/nix/flake-parts%20%5B%5D/lib.nix#L25
################################################################################
{
  inputs,
  lib,
  ...
}:
{
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
          inputs.self.modules.nixos.master-overlay
          inputs.self.modules.nixos.minimal
          inputs.self.modules.nixos.remote-deploy
          { nixpkgs.hostPlatform = lib.mkDefault system; }
        ];
      };
    };

    mkDarwin = system: name: {
      ${name} = inputs.nix-darwin.lib.darwinSystem {
        modules = [
          inputs.self.modules.darwin.${name}
          inputs.self.modules.darwin.unstable-overlay
          inputs.self.modules.darwin.master-overlay
          inputs.self.modules.darwin.minimal
          { nixpkgs.hostPlatform = lib.mkDefault system; }
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
