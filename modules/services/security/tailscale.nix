# modules/services/security/tailscale.nix
################################################################################
# Tailscale is a WireGuard-based mesh VPN that connects all hosts privately.
# https://tailscale.com/ | https://search.nixos.org/options?query=services.tailscale
#
# NixOS: authenticates headlessly via a sops-encrypted auth key and serves
# Tailscale SSH only on hosts that do not run the OpenSSH daemon.
#
# Darwin: installs the Tailscale app via Homebrew. The app ships its own
# tailscaled and system extension, so services.tailscale is left off here to
# avoid a second daemon competing for the same state.
################################################################################
{ inputs, ... }:
{
  flake.aspects.services.security.tailscale = {
    darwin =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          unstable.tailscale
        ];

        homebrew.casks = [ "tailscale-app" ];
      };

    nixos =
      { config, lib, ... }:
      {
        persistentDirectories = [ "/var/lib/tailscale" ];

        sops.secrets.tailscale-auth-key.sopsFile =
          inputs.self + "/secrets/${config.networking.hostName}/tailscale-auth-key.secret.yaml";

        services.tailscale = {
          enable = true;
          authKeyFile = config.sops.secrets.tailscale-auth-key.path;

          extraSetFlags = [ "--ssh=${lib.boolToString (!config.services.openssh.enable)}" ];
        };
      };
  };
}
