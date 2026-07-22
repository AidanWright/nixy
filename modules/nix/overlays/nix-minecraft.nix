# modules/nix/overlays/nix-minecraft.nix
################################################################################
# https://github.com/Infinidoge/nix-minecraft
# Adds the nix-minecraft overlay so NixOS hosts can reference Minecraft server
# packages (e.g. `pkgs.fabricServers.fabric-1_21`) from nixpkgs.
################################################################################
{ inputs, ... }:
{
  flake-file.inputs.nix-minecraft.url = "github:Infinidoge/nix-minecraft";

  flake.aspects.overlays.nix-minecraft.nixos = _: {
    nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];
  };
}
