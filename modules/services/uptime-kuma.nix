# modules/services/uptime-kuma.nix
################################################################################
# Uptime Kuma (https://github.com/louislam/uptime-kuma) is a self-hosted uptime
# and status monitoring tool. It is exposed only on the Tailscale interface.
################################################################################
{ ... }:
{
  flake.aspects.services.uptime-kuma.nixos =
    { ... }:
    {
      # DynamicUser redirects StateDirectory to /var/lib/private/uptime-kuma;
      # that is the real on-disk path impermanence must bind-mount.
      persistentDirectories = [ "/var/lib/private/uptime-kuma" ];

      services.uptime-kuma = {
        enable = true;

        settings = {
          HOST = "0.0.0.0";
          PORT = "3001";
        };
      };

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 3001 ];
    };
}
