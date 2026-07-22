# modules/services/homepage-dashboard.nix
################################################################################
# Homepage (https://gethomepage.dev/) is a customizable application dashboard
# and start page. It is exposed only on the Tailscale interface.
################################################################################
{ ... }:
{
  flake.aspects.services.homepage-dashboard.nixos =
    { ... }:
    {
      # DynamicUser redirects StateDirectory to /var/lib/private/homepage-dashboard;
      # that is the real on-disk path impermanence must bind-mount.
      persistentDirectories = [ "/var/lib/private/homepage-dashboard" ];

      services.homepage-dashboard = {
        enable = true;
        listenPort = 8082;

        # Allow access from any Tailscale hostname; the firewall below restricts
        # the network boundary to the tailnet interface.
        allowedHosts = "biggy,biggy.local,*";
      };

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8082 ];
    };
}
