# modules/system/basic/darwin/basic.nix
################################################################################
# Basic system settings: power management and sleep behaviour.
################################################################################
{ inputs, ... }:
{
  flake.modules.darwin.basic =
    { ... }:
    {
      imports = with inputs.self.modules.darwin; [
        determinate
        homebrew
        home-manager
        stylix
      ];

      power.sleep = {
        display = 5;
        computer = 10;
        harddisk = 5;
      };
    };
}
