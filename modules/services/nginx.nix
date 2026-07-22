# modules/services/nginx.nix
################################################################################
# nginx reverse proxy that terminates TLS for all public web services.
# https://nginx.org/ | https://search.nixos.org/options?query=services.nginx
################################################################################
{ ... }:
{
  flake.aspects.services.nginx.nixos =
    { ... }:
    {
      # TLS certificates live here; persisting avoids re-issuance and hitting
      # Let's Encrypt rate limits.
      persistentDirectories = [ "/var/lib/acme" ];

      services.nginx = {
        enable = true;

        virtualHosts."frame.aidanwright.dev" = {
          forceSSL = true;
          enableACME = true;

          locations."/" = {
            proxyPass = "http://127.0.0.1:8000";
            proxyWebsockets = true;
          };
        };

        virtualHosts."git.aidanwright.dev" = {
          forceSSL = true;
          enableACME = true;

          locations."/" = {
            proxyPass = "http://127.0.0.1:3000";
            extraConfig = ''
              client_max_body_size 512M;
            '';
          };
        };
      };

      # https://nixos.org/manual/nixos/stable/#module-security-acme
      # ACME automatically provisions and renews Let's Encrypt TLS certificates; `defaults.email` receives expiry notices.
      security.acme = {
        acceptTerms = true;
        defaults.email = "administrator@aidanwright.dev";
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
    };
}
