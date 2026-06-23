# modules/hosts/macbook-pro/configuration.nix
################################################################################
# macbook-pro host configuration.
################################################################################
{ inputs, ... }:
{
  flake.aspects.macbook-pro.darwin =
    { ... }:
    {
      imports = with inputs.self.modules.darwin; [
        basic
        hardening
        aidanwright
        cli-tools
        desktop-tools
        tailscale
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
