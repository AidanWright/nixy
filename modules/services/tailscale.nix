{ ... }:
{
  flake.modules.nixos.tailscale =
    { config, ... }:
    {
      services.tailscale = {
        enable = true;
        authKeyFile = config.sops.secrets.tailscale-auth-key.path;
      };
    };
}
