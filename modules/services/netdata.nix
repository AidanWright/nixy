# modules/services/netdata.nix
################################################################################
# Netdata (https://www.netdata.cloud/) is a real-time performance and health
# monitoring agent. It is exposed only on the Tailscale interface.
################################################################################
{ ... }:
{
  flake.aspects.services.netdata.nixos =
    { ... }:
    {
      persistentDirectories = [ "/var/lib/netdata" ];

      services.netdata = {
        enable = true;

        # https://learn.netdata.cloud/docs/netdata-agent/configuration/configuration-reference#registry
        # Disable the built-in Netdata registry; a self-hosted registry is not needed here.
        config.registry = {
          enabled = "no";
        };
      };

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 19999 ];
    };
}
