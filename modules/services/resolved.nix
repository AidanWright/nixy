# modules/services/resolved.nix
################################################################################
# systemd-resolved (https://systemd.network/resolved.conf.html,
# https://search.nixos.org/options?query=services.resolved) is the system DNS
# resolver. It is configured here to require DNS-over-TLS for all queries.
################################################################################
{ ... }:
{
  flake.aspects.services.resolved.nixos =
    { ... }:
    {
      services.resolved = {
        enable = true;

        settings.Resolve = {
          # Require TLS for all upstream DNS queries; fail if the resolver
          # does not support DoT rather than falling back to plaintext.
          DNSOverTLS = "true";

          # Cloudflare (1.1.1.1) and Quad9 (9.9.9.9) both support DoT on port 853.
          DNS = [
            "1.1.1.1"
            "1.0.0.1"
            "9.9.9.9"
            "149.112.112.112"
          ];
        };
      };
    };
}
