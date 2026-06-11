# modules/hosts/macbook-pro/configuration.nix
################################################################################
# macbook-pro host configuration.
################################################################################
{ inputs, ... }:
{
  flake.modules.darwin.macbook-pro =
    { ... }:
    {
      imports = with inputs.self.modules.darwin; [
        basic
        cli-tools
        desktop
        office
        spotify
        steam
        stremio
      ];
      networking.hostName = "macbook-pro";
      system.primaryUser = "aidanwright";
    };
}
