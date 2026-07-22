# modules/services/minecraft.nix
################################################################################
# Fabric Minecraft server managed by nix-minecraft, running on biggy.
# https://github.com/Infinidoge/nix-minecraft | https://search.nixos.org/options?query=services.minecraft-servers
#
# Console: tmux -S /run/minecraft/main.sock attach
# Send command: mc cmd "<command>"
# Manage: mc start | stop | restart | backup
################################################################################
{ inputs, ... }:
{
  flake.aspects =
    { aspects, ... }:
    {
      services.minecraft = {
        includes = with aspects; [ overlays.nix-minecraft ];

        nixos =
          { pkgs, ... }:
          {
            persistentDirectories = [ "/srv/minecraft" ];

            imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];

            services.minecraft-servers = {
              enable = true;
              eula = true;
              openFirewall = true;
              dataDir = "/srv/minecraft";

              servers.main = {
                enable = true;
                package = pkgs.fabricServers.fabric-26_2;

                # Aikar's GC flags, tuned for a ~16 GB host (8 GB heap).
                jvmOpts = "-Xms4G -Xmx8G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1";

                serverProperties = {
                  server-port = 25565;
                  white-list = true;
                  difficulty = "normal";
                  motd = "biggy";
                };

                # Owner populates these after first deploy via `mc cmd whitelist add <name>`,
                # or by editing this file and rebuilding.
                whitelist = { };
                operators = { };

                enableReload = true;
              };
            };

            environment.systemPackages = [
              (pkgs.writeShellApplication {
                name = "mc";
                runtimeInputs = with pkgs; [
                  tmux
                  gnutar
                  systemd
                ];
                text = ''
                  set -euo pipefail

                  usage() {
                    echo "Usage: mc <console|cmd|backup|start|stop|restart>"
                    echo ""
                    echo "  console          Attach to the server console"
                    echo "  cmd <command>    Send a command to the running server"
                    echo "  backup           Archive the world to /srv/minecraft/backups"
                    echo "  start            Start the server"
                    echo "  stop             Stop the server"
                    echo "  restart          Restart the server"
                    exit 1
                  }

                  SOCK=/run/minecraft/main.sock
                  SERVICE=minecraft-server-main.service

                  case "''${1:-}" in
                    console)
                      tmux -S "$SOCK" attach
                      ;;
                    cmd)
                      shift
                      tmux -S "$SOCK" send-keys "$*" Enter
                      ;;
                    backup)
                      DEST=/srv/minecraft/backups
                      mkdir -p "$DEST"
                      ARCHIVE="$DEST/main-$(date +%Y%m%dT%H%M%S).tar.gz"
                      tar -czf "$ARCHIVE" -C /srv/minecraft main
                      echo "Backed up to $ARCHIVE"
                      ;;
                    start)
                      systemctl start "$SERVICE"
                      ;;
                    stop)
                      systemctl stop "$SERVICE"
                      ;;
                    restart)
                      systemctl restart "$SERVICE"
                      ;;
                    *)
                      usage
                      ;;
                  esac
                '';
              })
            ];
          };
      };
    };
}
