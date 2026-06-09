# modules/services/nginx.nix
################################################################################
#
################################################################################
{ ... }:
{
  flake.modules.nixos.nginx =
    { ... }:
    {
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
      };

      security.acme = {
        acceptTerms = true;
        defaults.email = "claude@aidanwright.dev";
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
    };
}
