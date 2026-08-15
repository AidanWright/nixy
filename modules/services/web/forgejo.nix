# modules/services/web/forgejo.nix
################################################################################
# Forgejo is a lightweight, self-hosted Git forge — a community fork of Gitea.
# https://forgejo.org/ | https://search.nixos.org/options?query=services.forgejo
#
# Runs on 127.0.0.1:3000; nginx terminates TLS and proxies inbound traffic.
# Uses SQLite (no external database dependency; suitable for a single-owner instance).
################################################################################
{ inputs, ... }:
{
  flake.aspects.services.web.forgejo.nixos =
    { ... }:
    {
      imports = [
        (inputs.self.lib.mkServiceProfile {
          name = "forgejo";
          packages = { config, ... }: [ config.services.forgejo.package ];
          rules =
            { config, ... }:
            ''
              ${config.services.forgejo.stateDir}/ r,
              ${config.services.forgejo.stateDir}/** rwkl,

              # git runs the per-repository hooks forgejo writes here, so they
              # need execute on top of the write grant above.
              ${config.services.forgejo.stateDir}/repositories/**/hooks/** ix,

              # SQLite needs to create sibling journal and WAL files next to the
              # database, and to take locks on them.
              ${config.services.forgejo.stateDir}/data/*.db* rwk,

              /run/forgejo/ rw,
              /run/forgejo/** rwkl,

              owner @{PROC}/@{pid}/** r,
            '';
        })
      ];

      persistentDirectories = [ "/var/lib/forgejo" ];

      services.forgejo = {
        enable = true;

        database.type = "sqlite3";

        settings = {
          server = {
            DOMAIN = "git.aidanwright.dev";
            ROOT_URL = "https://git.aidanwright.dev/";
            # Bind loopback only — nginx terminates TLS and proxies inbound traffic.
            HTTP_ADDR = "127.0.0.1";
            HTTP_PORT = 3000;
          };

          service = {
            # Private instance; only the owner should have an account.
            DISABLE_REGISTRATION = true;
          };

          session.COOKIE_SECURE = true;
        };
      };
    };
}
