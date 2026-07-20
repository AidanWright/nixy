# modules/services/tailscale.nix
################################################################################
#
################################################################################
{ inputs, ... }:
{
  flake.aspects.services.tailscale = {
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
        # inputs.self coerces to flake root path
        sops.secrets.tailscale-auth-key.sopsFile =
          inputs.self + "/${config.networking.hostName}/tailscale-auth-key.secret.yaml";

        services.tailscale = {
          enable = true;
          authKeyFile = config.sops.secrets.tailscale-auth-key.path;
        };
      };
  };
}
