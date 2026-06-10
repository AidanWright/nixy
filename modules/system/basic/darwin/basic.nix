# modules/system/basic/darwin/basic.nix
################################################################################
# Basic system settings: power management and sleep behaviour.
################################################################################
{ ... }:
{
  flake.modules.darwin.basic =
    { ... }:
    {
      power.sleep.display = 5;
      power.sleep.computer = 10;
      power.sleep.harddisk = 5;
      #power.restartAfterFreeze = true;
      #power.restartAfterPowerFailure = true;
    };
}
