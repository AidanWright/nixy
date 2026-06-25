# modules/system/virtualization/nixos-shell.nix
################################################################################
# Exposes nix run --impure .#nixosConfigurations.<host>.config.system.build.nixos-shell
# --impure is required: reads $SHELL and $HOME to mount the host's home directory
# into the VM, and detects the host platform for Darwin compatibility.
# See: https://github.com/Mic92/nixos-shell
################################################################################
{ ... }:
{
  flake-file.inputs.nixos-shell = {
    url = "github:Mic92/nixos-shell";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.aspects.virt.nixos-shell.nixos =
    { inputs, ... }:
    {
      imports = [ inputs.nixos-shell.nixosModules.nixos-shell ];
    };
}
