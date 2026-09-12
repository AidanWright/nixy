# modules/hosts/biggy/flake-parts.nix
################################################################################
# Registers biggy in flake.nixosConfigurations.
################################################################################
{
  inputs,
  ...
}:
{
  #flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "biggy";
  flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" "biggy";
}
