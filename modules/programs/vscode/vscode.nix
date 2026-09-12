# modules/programs/vscode/vscode.nix
################################################################################
# Visual Studio Code.
################################################################################
{ ... }:
{
  flake.aspects.programs.vscode.base.homeManager =
    {
      config,
      options,
      lib,
      pkgs,
      ...
    }:
    let
      userDirectory =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "${config.home.homeDirectory}/Library/Application Support/Code/User"
        else
          "${config.xdg.configHome}/Code/User";

      settingsPath =
        profile:
        "${userDirectory}/${lib.optionalString (profile != "default") "profiles/${profile}/"}settings.json";
    in
    {
      # Stylix writes the theme into programs.vscode.profiles, so it cannot
      # read the profile names back off that option to decide what to theme.
      options.vscodeProfiles = lib.mkOption {
        type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
        default = { };
        description = "Visual Studio Code profiles. Every profile listed here is themed by stylix.";
      };

      config =
        let
          generatesSettings =
            profile:
            let
              inherit (config.programs.vscode.profiles.${profile})
                userSettings
                enableUpdateCheck
                enableExtensionUpdateCheck
                ;
            in
            userSettings != { } || enableUpdateCheck == false || enableExtensionUpdateCheck == false;

          settingsProfiles = lib.filterAttrs (profile: _: generatesSettings profile) config.vscodeProfiles;
        in
        {
          vscodeProfiles.default = { };

          programs.vscode = {
            enable = true;
            package = lib.mkForce pkgs.master.vscode;
            profiles = config.vscodeProfiles;
          };

          # Extensions persist state into settings.json; the ESP-IDF one fails to
          # activate when it cannot. Home-manager still generates the content and
          # rewrites it on every switch.
          home.file = lib.mapAttrs' (
            profile: _: lib.nameValuePair (settingsPath profile) { enable = false; }
          ) settingsProfiles;

          home.activation.vscodeWritableSettings =
            # linkGeneration removes the previous generation's files, and would
            # otherwise delete this copy again.
            lib.hm.dag.entryAfter [ "linkGeneration" ] (
              lib.concatLines (
                lib.mapAttrsToList (
                  profile: _:
                  let
                    path = settingsPath profile;
                  in
                  "run install -D -m 600 ${config.home.file.${path}.source} ${lib.escapeShellArg path}"
                ) settingsProfiles
              )
            );
        }
        // lib.optionalAttrs (options ? stylix) {
          stylix.targets.vscode.profileNames = lib.attrNames config.vscodeProfiles;
        };
    };
}
