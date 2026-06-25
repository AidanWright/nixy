# modules/services/ssh.nix
################################################################################
#
################################################################################
{ ... }:
{
  flake.aspects.services.ssh.nixos =
    { ... }:
    {
      services.openssh = {
        enable = true;
        # Firewall is opened per-interface below instead.
        openFirewall = false;
      };

      # SSH is only reachable via the Tailscale interface.
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];
    };
}
