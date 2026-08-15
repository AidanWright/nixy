# modules/services/web/latex/zoho-backup.nix
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
  flake.aspects.services.web.latex.zoho-backup.nixos =
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
    {
      # Imported unconditionally and switched off from within, because
      # secretExists is derived from `config` and `imports` may not depend on it.
      imports = [
        (inputs.self.lib.mkServiceProfile {
          name = "zoho-backup";
          enable = _: secretExists;
          packages = { pkgs, ... }: [ pkgs.rclone ];
          rules =
            { config, ... }:
            ''
              # Read-only on the source: a backup job has no reason to modify
              # what it is backing up.
              /srv/latex/ r,
              /srv/latex/** r,

              ${config.sops.secrets.rclone-zoho.path} r,

              /var/cache/zoho-backup/ rw,
              /var/cache/zoho-backup/** rwkl,

              owner @{PROC}/@{pid}/** r,
            '';
        })
      ];

      config = lib.mkIf secretExists {
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

            # rclone caches under $HOME by default, which ProtectHome makes
            # read-only. A private cache directory keeps the home directory out
            # of the picture entirely.
            CacheDirectory = "zoho-backup";
            ExecStart = "${pkgs.rclone}/bin/rclone --config ${config.sops.secrets.rclone-zoho.path} --cache-dir %C/zoho-backup sync /srv/latex zoho:Backups/latex";

            # A backup job needs to read one directory and reach the network,
            # nothing else. ProtectSystem=strict leaves the whole filesystem
            # read-only, which suits a job that only ever reads its source.
            NoNewPrivileges = true;
            ProtectSystem = "strict";
            ProtectHome = "read-only";
            PrivateTmp = true;
            PrivateDevices = true;
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectControlGroups = true;
            RestrictSUIDSGID = true;
            RestrictNamespaces = true;
            LockPersonality = true;
            RestrictAddressFamilies = [
              "AF_UNIX"
              "AF_INET"
              "AF_INET6"
            ];
            SystemCallArchitectures = "native";
            CapabilityBoundingSet = [ "" ];
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
    };
}
