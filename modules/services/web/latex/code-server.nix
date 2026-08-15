# modules/services/web/latex/code-server.nix
################################################################################
# https://github.com/coder/code-server
# VS Code in the browser, hardened with a dedicated system user and systemd
# confinement (no new privileges, strict filesystem, private /tmp).
#
# The LaTeX workspace lives at /srv/latex (group `latex`, setgid + default ACL)
# so Syncthing and Zoho-backup, running as `aidanwright`, share access without
# needing aidanwright's home directory.
#
# Access: https://<tailscale-hostname>:4443
# Password: set via sops secret once present (argon2 hash); no-auth until then.
################################################################################
{ inputs, ... }:
{
  flake.aspects =
    { aspects, ... }:
    {
      services.web.latex.code-server = {
        includes = with aspects; [ overlays.vscode-extensions ];

        nixos =
          {
            config,
            pkgs,
            lib,
            ...
          }:
          let
            # The editor is Tailscale-firewalled either way: it runs password-authed
            # once the owner creates secrets/<host>/code-server-password.secret.yaml
            # (containing HASHED_PASSWORD=<argon2>), and falls back to tailnet-gated
            # no-auth until then, so the config evaluates before that file exists.
            secretExists = builtins.pathExists (
              inputs.self + "/secrets/${config.networking.hostName}/code-server-password.secret.yaml"
            );

            latexWorkshop = pkgs.nix-vscode-extensions.open-vsx.james-yu.latex-workshop;

            extensionsDir = pkgs.symlinkJoin {
              name = "code-server-extensions";
              paths = [ latexWorkshop ];
            };

            # Seed LaTeX Workshop defaults and security settings on first start
            # (tmpfiles `C` copies the file only when the destination is absent,
            # so user edits survive subsequent rebuilds).
            defaultSettings = pkgs.writeText "code-server-latex-settings.json" (
              builtins.toJSON {
                "latex-workshop.latex.outDir" = "%DIR%";
                "latex-workshop.latex.recipe.default" = "lastUsed";
                "latex-workshop.latex.recipes" = [
                  {
                    name = "latexmk";
                    tools = [ "latexmk" ];
                  }
                ];
                "latex-workshop.latex.tools" = [
                  {
                    name = "latexmk";
                    command = "latexmk";
                    args = [
                      "-synctex=1"
                      "-interaction=nonstopmode"
                      "-file-line-error"
                      "-pdf"
                      "-outdir=%OUTDIR%"
                      "%DOC%"
                    ];
                  }
                ];
                "latex-workshop.view.pdf.viewer" = "tab";

                # Require explicit trust before running workspace tasks or
                # extensions; prevents a compromised project from auto-executing code.
                "security.workspace.trust.enabled" = true;

                # Automatic task execution is a code-execution vector; require
                # the user to opt in manually per session.
                "task.allowAutomaticTasks" = "off";

                # Prevent the extension marketplace from installing or updating
                # extensions at runtime; only the store-pinned set in extensionsDir
                # is available. There is no env-var hook in this version of
                # code-server that disables the gallery transport, so these settings
                # are the supported surface for that constraint.
                "extensions.autoUpdate" = false;
                "extensions.autoCheckUpdates" = false;
                "extensions.ignoreRecommendations" = true;
              }
            );
          in
          {
            imports = [ (inputs.self.lib.tailscaleOnlyPorts { tcp = [ 4443 ]; }) ];

            persistentDirectories = [
              "/srv/latex"
              "/var/lib/codeserver"
            ];

            users.groups.latex = { };
            users.groups.codeserver = { };

            users.users.codeserver = {
              isSystemUser = true;
              group = "codeserver";
              # latex group membership lets code-server read and write /srv/latex.
              extraGroups = [ "latex" ];
              home = "/var/lib/codeserver";
              createHome = true;
            };

            # aidanwright needs latex group membership to access /srv/latex via
            # Syncthing and rclone without sudo.
            users.users.aidanwright.extraGroups = [ "latex" ];

            services.code-server = {
              enable = true;
              user = "codeserver";
              group = "codeserver";
              host = "0.0.0.0";
              port = 4443;
              auth = if secretExists then "password" else "none";
              extensionsDir = "${extensionsDir}";
              userDataDir = "/var/lib/codeserver/code-server";
              # Open /srv/latex as the default workspace folder on launch.
              extraArguments = [ "/srv/latex" ];
              extraPackages = [
                pkgs.texliveFull
                pkgs.texlab
              ];
              disableTelemetry = true;
              disableUpdateCheck = true;
            };

            systemd.tmpfiles.rules = [
              # setgid bit (2770) ensures new files inherit the latex group so
              # both codeserver and aidanwright own what they create.
              "d /srv/latex 2770 aidanwright latex - -"

              # The default ACL grants group latex full access to everything
              # created here regardless of the creating process's umask, which
              # the setgid bit alone does not do. The A+ argument needs its own
              # `default:` prefix; without it systemd-tmpfiles silently sets no
              # default ACL at all.
              "a+ /srv/latex - - - - g:latex:rwx"
              "A+ /srv/latex - - - - default:g:latex:rwx"

              # tmpfiles creates missing parents as root:root 0755, so the
              # directories must be declared before the file that lives in them
              # or code-server cannot write its own settings back.
              "d /var/lib/codeserver/code-server 0700 codeserver codeserver - -"
              "d /var/lib/codeserver/code-server/User 0700 codeserver codeserver - -"
              "C /var/lib/codeserver/code-server/User/settings.json 0644 codeserver codeserver - ${defaultSettings}"
            ];

            systemd.services.code-server.serviceConfig = {
              # Block any exec inside the process from gaining new privileges via
              # setuid/setgid binaries or file capabilities.
              NoNewPrivileges = true;
              # Make /usr, /boot, /etc read-only and hide most of /; texlive and
              # extensions live in /nix/store which remains readable.
              ProtectSystem = "strict";
              # Prevent access to real home directories; codeserver has no login home.
              ProtectHome = true;
              # Give the process its own private /tmp, invisible to other services.
              PrivateTmp = true;
              # Prevent the process from creating setuid/setgid files.
              RestrictSUIDSGID = true;
              # The only paths that need to be writable at runtime.
              ReadWritePaths = [
                "/srv/latex"
                "/var/lib/codeserver"
              ];
            };

            # Holds the argon2 hash used as HASHED_PASSWORD so the secret never
            # enters the nix store (hashedPassword would put it in the derivation).
            # systemd reads the EnvironmentFile as root before dropping privileges,
            # so the sandboxing above does not block it.
            # The file must contain a single line: HASHED_PASSWORD=<argon2-hash>.
            sops.secrets = lib.mkIf secretExists {
              code-server-password.sopsFile =
                inputs.self + "/secrets/${config.networking.hostName}/code-server-password.secret.yaml";
            };

            systemd.services.code-server.serviceConfig.EnvironmentFile =
              lib.mkIf secretExists config.sops.secrets.code-server-password.path;
          };
      };
    };
}
