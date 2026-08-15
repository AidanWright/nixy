# modules/users/aidanwright/flake-parts.nix
################################################################################
# Registers aidanwright's standalone home-manager configuration. Apply with:
#   nix run home-manager/release-26.05 -- switch --flake .#aidanwright
################################################################################
{ inputs, ... }:
{
  # The WSL box has no smart-card access, so it swaps the local gpg-agent for a
  # bridge to the Windows host agent.
  flake.homeConfigurations = inputs.self.lib.mkHomeManager "x86_64-linux" "aidanwright" [
    inputs.self.modules.homeManager."wsl.gpg-agent"
    { programs.home-manager.enable = true; }
  ];
}
