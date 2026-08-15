# modules/services/web/nginx.nix
################################################################################
# nginx reverse proxy that terminates TLS for all public web services.
# https://nginx.org/ | https://search.nixos.org/options?query=services.nginx
################################################################################
{ inputs, ... }:
{
  flake.aspects.services.web.nginx.nixos =
    { ... }:
    {
      imports = [
        (inputs.self.lib.mkServiceProfile {
          name = "nginx";
          packages = { config, ... }: [ config.services.nginx.package ];
          rules = _: ''
            # Binding 80/443 and dropping the worker processes to the nginx user
            # are the only privileges the master process keeps.
            capability net_bind_service,
            capability setuid,
            capability setgid,

            /etc/nginx/ r,
            /etc/nginx/** r,

            # Append only, so a compromised worker cannot truncate the access
            # log to erase its own requests.
            /var/log/nginx/ r,
            /var/log/nginx/** a,

            /var/cache/nginx/ r,
            /var/cache/nginx/** rwkl,
            /run/nginx/ rw,
            /run/nginx/** rwkl,

            # Includes the certificate private keys, which nginx must read to
            # serve TLS. Read-only: renewal is the acme service's job.
            /var/lib/acme/ r,
            /var/lib/acme/** r,

            owner @{PROC}/@{pid}/** r,
          '';
        })
      ];

      # TLS certificates live here; persisting avoids re-issuance and hitting
      # Let's Encrypt rate limits.
      persistentDirectories = [ "/var/lib/acme" ];

      services.nginx = {
        enable = true;

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
