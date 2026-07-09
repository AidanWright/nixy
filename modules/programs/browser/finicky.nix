# modules/programs/browser/finicky.nix
################################################################################
# Routes URLs by domain. Finicky becomes the macOS default browser and hands
# streaming sites (which need DRM LibreWolf refuses to play) to Safari, sending
# everything else to LibreWolf. Launches at login and hides its own menu bar
# icon (macOS's native "Allow in the Menu Bar" toggle lives in a SIP data vault
# and cannot be set declaratively).
################################################################################
{ ... }:
let
  streamingHosts = import ./_streaming-services.nix;
  hostsArray = builtins.concatStringsSep ", " (map (host: ''"${host}"'') streamingHosts);
in
{
  flake.aspects.programs.browser.finicky.darwin =
    {
      config,
      pkgs,
      ...
    }:
    {
      homebrew.casks = [ "finicky" ];

      # Launch Finicky at login so it is already dispatching links before the
      # first one is opened. `open -gb` resolves the app through LaunchServices
      # by bundle id (no hard-coded path) without pulling it to the foreground.
      launchd.user.agents.finicky = {
        serviceConfig = {
          ProgramArguments = [
            "/usr/bin/open"
            "-gb"
            "se.johnste.finicky"
          ];
          RunAtLoad = true;
        };
      };

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
              options: {
                hideIcon: true,
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
