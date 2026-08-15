# modules/services/monitor/honeypot.nix
################################################################################
# endlessh-go SSH tarpit (https://github.com/shizunge/endlessh-go) that slowly
# feeds an endless SSH banner to public scanners on port 22, keeping real sshd
# reachable only over Tailscale.
################################################################################
{ ... }:
{
  flake.aspects.services.monitor.honeypot.nixos =
    {
      config,
      lib,
      ...
    }:
    let
      tarpitPort = config.services.endlessh-go.port;

      # Emitted once to add and once to delete, so the two directions cannot
      # drift apart. These are iptables commands, so they are silently dropped
      # if networking.nftables.enable is ever turned on.
      redirectToTarpit =
        op: suffix:
        lib.concatMapStringsSep "\n" (rule: "iptables -t nat -${op} PREROUTING ${rule}${suffix}") [
          "-i lo -p tcp --dport 22 -j RETURN"
          "! -i tailscale0 -p tcp --dport 22 -j REDIRECT --to-ports ${toString tarpitPort}"
        ];
    in
    {
      services.endlessh-go = {
        enable = true;
        listenAddress = "0.0.0.0";
        # Public :22 is redirected here by the NAT rule below.
        port = 2222;
        prometheus.enable = true;

        # nat/PREROUTING rewrites the destination port before the filter chain
        # runs, so the firewall sees the tarpit port rather than 22. Without
        # this the redirected packets are rejected and the tarpit never runs.
        openFirewall = true;
      };

      # Redirect TCP/22 arriving on any non-Tailscale, non-loopback interface to
      # the tarpit. This lets real sshd keep :22 — the interface firewall
      # (services.ssh) already limits sshd to tailscale0 — while public scanners
      # reaching any other interface are silently tarpitted without knowing a host
      # IP or public interface name.
      networking.firewall.extraCommands = redirectToTarpit "A" "";
      networking.firewall.extraStopCommands = redirectToTarpit "D" " 2>/dev/null || true";

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
