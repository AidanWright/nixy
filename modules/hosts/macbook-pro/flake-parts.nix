# modules/hosts/macbook-pro/flake-parts.nix
################################################################################
# Registers macbook in flake.darwinConfigurations.
################################################################################
{
  inputs,
  ...
}:
{
  flake.darwinConfigurations = inputs.self.lib.mkDarwin "aarch64-darwin" "macbook-pro";
}
