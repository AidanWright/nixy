# modules/hosts/biggy/flake-parts.nix
################################################################################
# Registers macbook in flake.darwinConfigurations.
################################################################################
{
  inputs,
  ...
}:
{
  flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" "biggy";
}
