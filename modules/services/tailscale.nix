# modules/services/tailscale.nix
################################################################################
# Tailscale is a WireGuard-based mesh VPN that connects all hosts privately.
# https://tailscale.com/ | https://search.nixos.org/options?query=services.tailscale
#
# NixOS: authenticates headlessly via a sops-encrypted auth key.
# Darwin: installs the Tailscale app via Homebrew.
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
        persistentDirectories = [ "/var/lib/tailscale" ];

        sops.secrets.tailscale-auth-key.sopsFile =
          inputs.self + "/secrets/${config.networking.hostName}/tailscale-auth-key.secret.yaml";

        services.tailscale = {
          enable = true;
          authKeyFile = config.sops.secrets.tailscale-auth-key.path;
        };
      };
  };
}
