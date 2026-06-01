# modules/hosts/macbook/flake-parts.nix
################################################################################
# boilerplate to enable our host as a host.
################################################################################
{
  inputs,
  ...
}:
{
  flake.darwinConfigurations = inputs.self.lib.mkDarwin "aarch64-darwin" "macbook";
}
