# modules/system/minimal/server.nix
################################################################################
# Shared hardened-server base that every server host includes once, following
# the dendritic pattern (https://github.com/Doc-Steve/dendritic-design-with-flake-parts/wiki).
# Pulls in kernel hardening, impermanence, secrets, SSH, and the core defensive
# and observability services. Leaner hosts (e.g. Smalls) can include this alone;
# fuller hosts add further service aspects on top.
################################################################################
{ ... }:
{
  flake.aspects =
    { aspects, ... }:
    {
      minimal.server = {
        includes = with aspects; [
          security.hardening
          security.impermanence
          security.sops
          services.ssh
          services.fail2ban
          services.crowdsec
          services.chrony
          services.resolved
          services.netdata
          services.honeypot
        ];
      };
    };
}
