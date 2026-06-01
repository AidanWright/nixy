# modules/hosts/macbook/configuration.nix
################################################################################
#
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
      ###
    ];
    networking.hostName = "macbook";

  };
}
