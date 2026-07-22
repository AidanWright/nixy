# modules/services/chrony.nix
################################################################################
# Chrony (https://chrony-project.org/) is an NTP client and server that
# supports Network Time Security (NTS) for authenticated time synchronization.
# Enabling chrony automatically disables systemd-timesyncd.
################################################################################
{ ... }:
{
  flake.aspects.services.chrony.nixos =
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
