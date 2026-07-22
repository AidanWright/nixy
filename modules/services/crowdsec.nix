# modules/services/crowdsec.nix
################################################################################
# CrowdSec (https://www.crowdsec.net/) is a collaborative behavioral intrusion
# detection system that shares IP reputation data across its community. It is
# paired with a firewall bouncer that drops flagged IPs at the nftables level.
################################################################################
{ ... }:
{
  flake.aspects.services.crowdsec.nixos =
    { ... }:
    {
      persistentDirectories = [ "/var/lib/crowdsec" ];

      services.crowdsec = {
        enable = true;

        hub.collections = [
          "crowdsecurity/sshd"
          "crowdsecurity/linux"
          "crowdsecurity/nginx"
        ];

        # https://docs.crowdsec.net/docs/data_sources/intro
        # Tell CrowdSec which log sources to ingest and how to parse them.
        localConfig.acquisitions = [
          {
            source = "journalctl";
            journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
            labels.type = "syslog";
          }
          {
            source = "file";
            filenames = [ "/var/log/nginx/*.log" ];
            labels.type = "nginx";
          }
        ];
      };

      services.crowdsec-firewall-bouncer = {
        enable = true;
        # Auto-registers against the local CrowdSec LAPI; no manual API key needed.
        registerBouncer.enable = true;
      };
    };
}
