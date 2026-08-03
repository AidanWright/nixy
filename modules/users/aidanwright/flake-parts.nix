# modules/users/aidanwright/flake-parts.nix
################################################################################
# Registers aidanwright's standalone home-manager configuration (used on the
# WSL Ubuntu box, which is not a NixOS/darwin host). Apply with:
#   nix run home-manager/release-26.05 -- switch --flake .#aidanwright
################################################################################
{ inputs, ... }:
{
  # The WSL box has no smart-card access, so it swaps the local gpg-agent for a
  # bridge to the Windows host agent (programs.gpg-wsl).
  flake.homeConfigurations = inputs.self.lib.mkHomeManager "x86_64-linux" "aidanwright" [
    inputs.self.modules.homeManager."programs.gpg-wsl"
  ];
}
