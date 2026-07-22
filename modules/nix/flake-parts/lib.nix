# modules/nix/flake-parts/lib.nix
################################################################################
# Exports mkNixos and mkDarwin helpers via flake.lib.
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
          inputs.self.modules.nixos."overlays.unstable"
          inputs.self.modules.nixos."overlays.master"
          inputs.self.modules.nixos."minimal.base"
          { nixpkgs.hostPlatform = lib.mkDefault system; }
        ];
      };
    };

    tailscaleOnlyPorts =
      {
        tcp ? [ ],
        udp ? [ ],
      }:
      {
        networking.firewall.interfaces.tailscale0 = {
          allowedTCPPorts = tcp;
          allowedUDPPorts = udp;
        };
      };

    mkDarwin = system: name: {
      ${name} = inputs.nix-darwin.lib.darwinSystem {
        modules = [
          inputs.self.modules.darwin.${name}
          inputs.self.modules.darwin."overlays.unstable"
          inputs.self.modules.darwin."overlays.master"
          inputs.self.modules.darwin."overlays.darwin-apps"
          inputs.self.modules.darwin."minimal.base"
          inputs.self.modules.darwin."security.all"
          inputs.self.modules.darwin."homebrew"
          inputs.self.modules.darwin."home-manager"
          { home-manager.sharedModules = [ inputs.self.modules.homeManager."security.sops" ]; }
          { nixpkgs.hostPlatform = lib.mkDefault system; }
        ];
      };
    };

  };
}
