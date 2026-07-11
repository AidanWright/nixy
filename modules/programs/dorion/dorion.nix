# modules/programs/dorion/dorion.nix
################################################################################
# Dorion (lightweight Discord client), as a per-user home-manager aspect: the
# package plus a declarative config.json and the active theme. home-manager owns
# these files, so settings are changed here in nix rather than the Dorion GUI.
################################################################################
{ ... }:
{
  # pnpm 9.15.9 is dorion's Tauri build dep; darwin class so useGlobalPkgs sees it.
  flake.aspects.programs.dorion.darwin =
    { ... }:
    {
      permittedInsecurePackages = [ "pnpm-9.15.9" ];
    };

  flake.aspects.programs.dorion.homeManager =
    { pkgs, ... }:
    let
      dorionDir = "Library/Application Support/dorion";
    in
    {
      home.packages = [ pkgs.unstable.dorion ];

      home.file."${dorionDir}/themes/midnight-vencord.css".source = ./midnight-vencord.css;

      home.file."${dorionDir}/config.json".text = builtins.toJSON {
        theme = "none";
        themes = [ "midnight-vencord.css" ];
        zoom = "1.0";
        client_type = "default";
        client_mods = [
          "Shelter"
          "Equicord"
        ];
        client_plugins = true;
        profile = "default";
        blur = "none";
        blur_css = true;
        cache_css = false;
        auto_clear_cache = false;
        use_native_titlebar = false;
        start_maximized = false;
        startup_minimized = false;
        open_on_startup = false;
        sys_tray = false;
        tray_icon_enabled = true;
        unread_badge = true;
        desktop_notifications = false;
        win7_style_notifications = false;
        push_to_talk = false;
        push_to_talk_keys = [ "RControl" ];
        keybinds = { };
        keybinds_enabled = true;
        streamer_mode_detection = false;
        multi_instance = false;
        disable_hardware_accel = false;
        autoupdate = false;
        update_notify = true;
        proxy_uri = "";
        rpc_server = false;
        rpc_process_scanner = true;
        rpc_ipc_connector = true;
        rpc_websocket_connector = true;
        rpc_secondary_events = true;
      };
    };
}
