# modules/system/minimal/darwin/base.nix
################################################################################
# Common settings for all darwin configurations. Conditionally imports the
# Nix-implementation-specific minimal module based on which Nix is active.
################################################################################
{
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.nix-darwin = {
    # nix-darwin versioning tracks nixpkgs — nix-darwin-26.05 requires nixos-26.05.
    url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # ↓  hacky solution allows us to run unfree packages from terminal like `nix run nixpkgs#steam`
  # Adds a legacyPackages output to this flake which allows unfree
  # We then later update the registry to use *this* output as system nixpkgs
  flake.legacyPackages = lib.genAttrs [ "aarch64-darwin" "x86_64-darwin" ] (
    system:
    import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    }
  );

  flake.modules.darwin.system-minimal =
    {
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        inputs.self.modules.darwin.determinate-minimal
        inputs.self.modules.darwin.lix-minimal
      ];

      # where we update the registry to include our unfree-nixpkgs
      environment.etc."nix/registry.json".text = builtins.toJSON {
        version = 2;
        flakes = [
          {
            from = {
              type = "indirect";
              id = "nixpkgs";
            };
            to = {
              type = "path";
              path = inputs.self.outPath;
            };
          }
        ];
      };

      nixpkgs.config.allowUnfree = lib.mkForce true;

      system.stateVersion = 6;

      environment.systemPackages = with inputs.nix-darwin.packages.${pkgs.stdenv.hostPlatform.system}; [
        darwin-option
        darwin-rebuild
        darwin-version
        darwin-uninstaller
      ];
    };
}
