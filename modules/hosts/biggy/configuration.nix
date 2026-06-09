# modules/hosts/biggy/configuration.nix
################################################################################
#
################################################################################
{ inputs, ... }:
{
  flake.modules.nixos.biggy =
    { ... }:
    {
      imports = with inputs.self.modules.nixos; [
        sops
        tailscale
        ssh
        nginx
      ];

      networking.hostName = "biggy";

      sops.secrets.tailscale-auth-key.sopsFile = ./tailscale-auth-key.yaml;
    };
}
