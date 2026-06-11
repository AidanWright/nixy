# modules/programs/kitty.nix
################################################################################
# Configures kitty terminal via home-manager.
################################################################################
{ ... }:
{
  flake.modules.darwin.kitty =
    { pkgs, config, ... }:
    {
      environment.systemPackages = [ pkgs.kitty ];
      home-manager.users.${config.system.primaryUser} = {
        programs.kitty = {
          enable = true;
          settings = {
            scrollback_lines = 10000;
            enable_audio_bell = false;
            window_padding_width = 8;
            confirm_os_window_close = 0;
          };
        };
        stylix.targets.kitty.enable = true;
      };
    };
}
