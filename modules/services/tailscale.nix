# modules/services/tailscale.nix
################################################################################
#
################################################################################
{ ... }:
{
  flake.aspects.tailscale.nixos =
    { config, ... }:
    {
      services.tailscale = {
        enable = true;
        authKeyFile = config.sops.secrets.tailscale-auth-key.path;
      };
    };
}
