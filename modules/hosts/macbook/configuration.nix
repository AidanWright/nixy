# modules/hosts/macbook/configuration.nix
################################################################################
# Imports all system modules for the macbook darwin host.
################################################################################
{
  inputs,
  ...
}:
{
  flake.modules.darwin.macbook = {
    imports = with inputs.self.modules.darwin; [
      determinate
      tartVm
    ];
    networking.hostName = "macbook";

  };
}
