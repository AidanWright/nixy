# modules/services/security/chrony.nix
################################################################################
# Chrony (https://chrony-project.org/) is an NTP client and server that
# supports Network Time Security (NTS) for authenticated time synchronization.
# Enabling chrony automatically disables systemd-timesyncd.
# Supposedly, chrony is more accurate than systemd-timesyncd. See:
# https://www.reddit.com/r/linuxadmin/comments/1fxjieu/is_systemdtimesyncd_suitable_for_use_on_servers/
################################################################################
{ ... }:
{
  flake.aspects.services.security.chrony.nixos =
    { ... }:
    {
      services.chrony = {
        enable = true;
        enableNTS = true;

        # https://chrony-project.org/doc/4.6.1/chrony.conf.html#server
        # Use servers that support NTS; the nixpkgs default pool does not.
        servers = [
          "time.cloudflare.com"
          "ntppool1.time.nl"
        ];
      };
    };
}
