# modules/programs/latex/latex-editor-app.nix
################################################################################
# Installs a "LaTeX Editor" macOS .app that opens the remote code-server
# instance (running on biggy over Tailscale) in the default browser. The bundle
# executable is a compiled makeBinaryWrapper launcher (not a shell script);
# macOS LaunchServices/Gatekeeper is unreliable launching script-based bundle
# executables.
################################################################################
{ ... }:
{
  flake.aspects.programs.latex.latex-editor-app.homeManager =
    { pkgs, ... }:
    let
      # biggy's Tailscale MagicDNS short-name + the port code-server listens on.
      # HTTPS is possible later via `tailscale serve` on biggy; for now plain HTTP
      # over the encrypted Tailscale tunnel is sufficient.
      latexEditorUrl = "http://biggy:4443";

      # A compiled Mach-O launcher (not a shell script): macOS
      # LaunchServices/Gatekeeper is unreliable launching script-based bundle
      # executables. makeBinaryWrapper cannot produce it here — it asserts its
      # target is an executable file, but /usr/bin/open lives outside the Nix
      # store and is absent from the build sandbox. This minimal exec wrapper
      # runs `/usr/bin/open <url>` (default browser = LibreWolf) instead.
      launcherSource = pkgs.writeText "latex-editor-launcher.c" ''
        #include <unistd.h>
        int main(void) {
          execl("/usr/bin/open", "open", "${latexEditorUrl}", (char *)0);
          return 1;
        }
      '';

      latexEditorApp = pkgs.runCommand "latex-editor-app" { nativeBuildInputs = [ pkgs.stdenv.cc ]; } ''
            contents="$out/Applications/LaTeX Editor.app/Contents"
            mkdir -p "$contents/MacOS"

            $CC -O2 -o "$contents/MacOS/LaTeX Editor" ${launcherSource}

            cat > "$contents/Info.plist" <<EOF
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>CFBundleExecutable</key><string>LaTeX Editor</string>
          <key>CFBundleIdentifier</key><string>dev.aidanwright.latex-editor</string>
          <key>CFBundleName</key><string>LaTeX Editor</string>
          <key>CFBundlePackageType</key><string>APPL</string>
          <key>CFBundleSignature</key><string>????</string>
          <key>CFBundleShortVersionString</key><string>1.0</string>
          <key>NSHighResolutionCapable</key><true/>
        </dict>
        </plist>
        EOF
      '';
    in
    {
      home.packages = [ latexEditorApp ];
    };
}
