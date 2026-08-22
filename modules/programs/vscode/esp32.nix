# modules/programs/vscode/esp32.nix
################################################################################
# ESP32 development profile. Extensions only: ESP-IDF is installed by hand and
# the extension finds it on its own.
################################################################################
{ ... }:
{
  flake.aspects =
    { aspects, ... }:
    {
      programs.vscode.esp32 = {
        includes = with aspects; [ programs.vscode.base ];

        homeManager =
          { pkgs, ... }:
          {
            vscodeProfiles.esp32 = {
              extensions =
                (with pkgs.nix-vscode-extensions.open-vsx; [
                  espressif.esp-idf-extension
                  wokwi.wokwi-vscode
                  llvm-vs-code-extensions.vscode-clangd
                  twxs.cmake
                ])
                # Microsoft never published these to Open VSX. ms-python.python is
                # an extension pack, and VS Code cannot install its members into
                # the read-only extensions directory, so they are listed too.
                ++ (with pkgs.nix-vscode-extensions.vscode-marketplace; [
                  ms-vscode-remote.remote-containers
                  ms-python.python
                  ms-python.vscode-pylance
                  ms-python.debugpy
                  ms-python.vscode-python-envs
                ]);

              # The extension runs ESP-IDF's activation script with
              # vscode.env.shell, which follows this setting, and only the
              # POSIX script is registered; fish cannot parse it.
              userSettings."terminal.integrated.defaultProfile.osx" = "bash";
            };
          };
      };
    };
}
