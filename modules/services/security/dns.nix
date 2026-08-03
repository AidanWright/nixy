# modules/services/security/dns.nix
################################################################################
# systemd-resolved (https://systemd.network/resolved.conf.html,
# https://search.nixos.org/options?query=services.resolved) is the system DNS
# resolver. It is configured here to require DNS-over-TLS for all queries.
################################################################################
{ ... }:
{
  flake.aspects.services.security.dns.nixos =
    { ... }:
    let
      nameservers = [
        "9.9.9.9" # dns.quad9.net
        "149.112.112.112" # dns.quad9.net
        "1.1.1.1" # dns.cloudflare.com
        "1.0.0.1" # dns.cloudflare.com
      ];
    in
    {
      networking.nameservers = nameservers;

      services.resolved = {
        enable = true;

        settings.Resolve = {
          # Require TLS for all upstream DNS queries; fail if the resolver
          # does not support DoT rather than falling back to plaintext.
          DNSOverTLS = "true";
          DNSSEC = "allow-downgrade";

          DNS = nameservers;
        };
      };
    };
}
