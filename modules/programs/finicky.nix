# modules/programs/finicky.nix
################################################################################
# Routes URLs by domain. Finicky becomes the macOS default browser and hands
# streaming sites (which need DRM LibreWolf refuses to play) to Safari, sending
# everything else to LibreWolf.
################################################################################
{ ... }:
let
  streamingHosts = import ./_streaming-services.nix;
  hostsArray = builtins.concatStringsSep ", " (map (host: ''"${host}"'') streamingHosts);
in
{
  flake.aspects.programs.finicky.darwin =
    {
      config,
      pkgs,
      ...
    }:
    {
      homebrew.casks = [ "finicky" ];

      # Point macOS at Finicky instead of a real browser; it re-dispatches every
      # opened link per the rules below. Replaces librewolf's own default-browser
      # agent, which would otherwise fight this one over the same launchd label.
      launchd.user.agents.defaultBrowser = {
        serviceConfig = {
          ProgramArguments = [
            "${pkgs.defaultbrowser}/bin/defaultbrowser"
            "finicky"
          ];
          RunAtLoad = true;
          StandardOutPath = "/tmp/defaultbrowser.log";
          StandardErrorPath = "/tmp/defaultbrowser.log";
        };
      };

      home-manager.users.${config.system.primaryUser} =
        { config, ... }:
        {
          home.file.".finicky.js".text = ''
            const streamingHosts = [${hostsArray}];

            const isStreaming = (host) =>
              streamingHosts.some((s) => host === s || host.endsWith("." + s));

            export default {
              defaultBrowser: {
                name: "${config.home.homeDirectory}/Applications/Home Manager Apps/LibreWolf.app",
              },
              handlers: [
                {
                  match: ({ url }) => isStreaming(url.host),
                  browser: "Safari",
                },
              ],
            };
          '';
        };
    };
}
