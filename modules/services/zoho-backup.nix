# modules/services/zoho-backup.nix
################################################################################
# https://rclone.org/zoho/
# Daily rclone sync from /srv/latex to Zoho WorkDrive.
#
# The backup activates once the owner creates
# secrets/biggy/rclone-zoho.secret.yaml, which must contain a full rclone.conf
# with a `[zoho]` remote obtained by running:
#
#   rclone config
#
# Choose "New remote" → name it `zoho` → select "Zoho WorkDrive" → complete
# the OAuth flow → write the resulting rclone.conf to the secret file and
# encrypt it with sops.
#
# Until that file exists, this module defines nothing active so flake eval
# passes on a fresh checkout.
################################################################################
{ inputs, ... }:
{
  flake.aspects.services.zoho-backup.nixos =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      # The timer and service are defined only once the owner has created and
      # encrypted the rclone config secret, so eval succeeds before it exists.
      secretExists = builtins.pathExists (
        inputs.self + "/secrets/${config.networking.hostName}/rclone-zoho.secret.yaml"
      );
    in
    lib.mkIf secretExists {
      sops.secrets.rclone-zoho = {
        sopsFile = inputs.self + "/secrets/${config.networking.hostName}/rclone-zoho.secret.yaml";
        # The rclone process runs as aidanwright and must read the decrypted
        # config; sops secrets are root-owned 0400 by default.
        owner = "aidanwright";
      };

      systemd.services.zoho-backup = {
        description = "rclone sync latex → Zoho WorkDrive";
        serviceConfig = {
          Type = "oneshot";
          User = "aidanwright";
          ExecStart = "${pkgs.rclone}/bin/rclone --config ${config.sops.secrets.rclone-zoho.path} sync /srv/latex zoho:Backups/latex";
        };
      };

      systemd.timers.zoho-backup = {
        description = "Daily Zoho WorkDrive backup timer";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };
    };
}
