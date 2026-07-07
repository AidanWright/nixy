# modules/programs/librewolf-safari-redirect.nix
################################################################################
# Catches streaming sites navigated to *inside* LibreWolf (typed in the bar or
# clicked in-page) and reopens them in Safari, completing what finicky.nix does
# for links opened from other apps.
#
# WebExtensions cannot launch another app directly, so this ships two coupled
# pieces: an unsigned in-tree extension that cancels streaming navigations and a
# native-messaging host that runs `open -a Safari`. The host manifest is written
# to both the Mozilla and LibreWolf lookup paths since forks differ on which
# they read.
################################################################################
{ ... }:
let
  streamingHosts = import ./_streaming-services.nix;
  hostPatterns = builtins.concatMap (host: [
    "*://${host}/*"
    "*://*.${host}/*"
  ]) streamingHosts;

  addonId = "stream-to-safari@local";
  nativeHostName = "stream_to_safari";
in
{
  flake.aspects.programs.browser.librewolf-safari-redirect.darwin =
    {
      config,
      pkgs,
      ...
    }:
    let
      manifest = {
        manifest_version = 2;
        name = "Stream to Safari";
        version = "1.0";
        browser_specific_settings.gecko.id = addonId;
        background.scripts = [ "background.js" ];
        permissions = [
          "webRequest"
          "webRequestBlocking"
          "nativeMessaging"
        ]
        ++ hostPatterns;
      };

      backgroundScript = ''
        browser.webRequest.onBeforeRequest.addListener(
          (details) => {
            browser.runtime.sendNativeMessage("${nativeHostName}", { url: details.url });
            return { cancel: true };
          },
          { urls: ${builtins.toJSON hostPatterns}, types: ["main_frame"] },
          ["blocking"],
        );
      '';

      extension =
        pkgs.runCommand "stream-to-safari-xpi"
          {
            nativeBuildInputs = [ pkgs.zip ];
            passthru.addonId = addonId;
          }
          ''
            mkdir source
            cp ${pkgs.writeText "manifest.json" (builtins.toJSON manifest)} source/manifest.json
            cp ${pkgs.writeText "background.js" backgroundScript} source/background.js

            target="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
            mkdir -p "$target"
            (cd source && zip -r -X "$target/${addonId}.xpi" .)
          '';

      nativeHost = pkgs.writers.writePython3Bin nativeHostName { } ''
        import json
        import struct
        import subprocess
        import sys

        header = sys.stdin.buffer.read(4)
        if len(header) == 4:
            length = struct.unpack("<I", header)[0]
            message = json.loads(sys.stdin.buffer.read(length))
            url = message.get("url")
            if url:
                subprocess.run(["/usr/bin/open", "-a", "Safari", url], check=False)
      '';

      nativeManifest = builtins.toJSON {
        name = nativeHostName;
        description = "Reopens streaming URLs from LibreWolf in Safari";
        path = "${nativeHost}/bin/${nativeHostName}";
        type = "stdio";
        allowed_extensions = [ addonId ];
      };
    in
    {
      home-manager.users.${config.system.primaryUser} = {
        programs.librewolf.profiles.default = {
          # LibreWolf refuses unsigned add-ons by default; this in-tree extension
          # is not submitted to Mozilla, so signature enforcement must be off.
          settings."xpinstall.signatures.required" = false;
          extensions.packages = [ extension ];
        };

        home.file = {
          "Library/Application Support/Mozilla/NativeMessagingHosts/${nativeHostName}.json".text =
            nativeManifest;
          "Library/Application Support/LibreWolf/NativeMessagingHosts/${nativeHostName}.json".text =
            nativeManifest;
        };
      };
    };
}
