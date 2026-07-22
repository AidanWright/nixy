# modules/services/honeypot.nix
################################################################################
# endlessh-go SSH tarpit (https://github.com/shizunge/endlessh-go) that slowly
# feeds an endless SSH banner to public scanners on port 22, keeping real sshd
# reachable only over Tailscale.
################################################################################
{ ... }:
{
  flake.aspects.services.honeypot.nixos =
    { ... }:
    {
      services.endlessh-go = {
        enable = true;
        listenAddress = "0.0.0.0";
        # Run on 2222; public :22 is redirected here by the NAT rule below.
        port = 2222;
        prometheus.enable = true;
      };

      # Redirect TCP/22 arriving on any non-Tailscale, non-loopback interface to
      # the tarpit on 2222. This lets real sshd keep :22 — the interface firewall
      # (services.ssh) already limits sshd to tailscale0 — while public scanners
      # reaching any other interface are silently tarpitted without knowing a host
      # IP or public interface name.
      networking.firewall.extraCommands = ''
        iptables -t nat -A PREROUTING -i lo -p tcp --dport 22 -j RETURN
        iptables -t nat -A PREROUTING ! -i tailscale0 -p tcp --dport 22 -j REDIRECT --to-ports 2222
      '';
      networking.firewall.extraStopCommands = ''
        iptables -t nat -D PREROUTING -i lo -p tcp --dport 22 -j RETURN 2>/dev/null || true
        iptables -t nat -D PREROUTING ! -i tailscale0 -p tcp --dport 22 -j REDIRECT --to-ports 2222 2>/dev/null || true
      '';

      # Expose endlessh-go Prometheus metrics (default port 2112) only over Tailscale.
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 2112 ];

      # systemd.services.confinement.enable is intentionally omitted: the
      # upstream endlessh-go NixOS module already applies an equivalent chroot
      # via RootDirectory + BindReadOnlyPaths, and the two mechanisms conflict
      # on that option (https://search.nixos.org/options?query=systemd.services.confinement).
      # The module also sets NoNewPrivileges, ProtectSystem, ProtectHome,
      # PrivateTmp, RestrictSUIDSGID, and the full @system-service syscall filter.
    };
}
