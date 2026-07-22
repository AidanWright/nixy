# modules/services/fail2ban.nix
################################################################################
# Fail2ban (https://github.com/fail2ban/fail2ban) scans log files and bans IPs
# that show signs of repeated authentication failures. The sshd jail is enabled
# by default.
################################################################################
{ ... }:
{
  flake.aspects.services.fail2ban.nixos =
    { ... }:
    {
      persistentDirectories = [ "/var/lib/fail2ban" ];

      services.fail2ban = {
        enable = true;
        maxretry = 5;
        bantime = "1h";
        ignoreIP = [
          "127.0.0.1/8"
          "::1"
          # Tailscale CGNAT range — trusted overlay-network peers must never be banned.
          "100.64.0.0/10"
        ];

        jails.sshd.settings = {
          enabled = true;
        };
      };
    };
}
