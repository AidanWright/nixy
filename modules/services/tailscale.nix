# modules/services/tailscale.nix
################################################################################
#
################################################################################
{ ... }:
{
  flake.aspects.tailscale =
    { ... }:
    {
      darwin = 
        { pkgs, ... }:
        {
          environment.systemPackages = with pkgs; [ 
            unstable.tailscale
          ];
      
          homebrew.casks = [ "tailscale-app" ];

          services.tailscale.enable = true; 
        };

      nixos =
        { config, ... }:
        {
          services.tailscale = {
            enable = true;
            authKeyFile = config.sops.secrets.tailscale-auth-key.path;
          };
        };
    };
}
