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

            imports = [
              inputs.nix-minecraft.nixosModules.minecraft-servers

              # nix-minecraft already applies systemd hardening, so
              # this adds path confinement on top rather than repeating it.
              (inputs.self.lib.mkServiceProfile {
                name = "minecraft";
                unit = "minecraft-server-main";
                packages = { config, ... }: [ config.services.minecraft-servers.servers.main.package ];
                rules =
                  { config, ... }:
                  ''
                    ${config.services.minecraft-servers.dataDir}/ r,
                    ${config.services.minecraft-servers.dataDir}/** rwkl,

                    # tmux control socket, created under RuntimeDirectory=minecraft.
                    /run/minecraft/ rw,
                    /run/minecraft/** rwkl,

                    # The JVM sizes its heap from cgroup limits and reads its own
                    # process state on startup.
                    owner @{PROC}/@{pid}/** r,
                    @{sys}/fs/cgroup/** r,
                  '';
              })
            ];

            services.minecraft-servers = {
              enable = true;
              eula = true;
              openFirewall = true;
              dataDir = "/srv/minecraft";

              servers.main = {
                enable = true;
                package = pkgs.fabricServers.fabric;

                # Aikar's GC flags, tuned for a ~16 GB host (8 GB heap).
                #jvmOpts = "-Xms4G -Xmx8G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1";

                jvmOpts = "-Xms4G -Xmx8G";

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

              };
            };
          };
      };
    };
}
