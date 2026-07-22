# modules/services/ssh.nix
################################################################################
# OpenSSH server, hardened and reachable only over the Tailscale interface.
# https://search.nixos.org/options?query=services.openssh
################################################################################
{ ... }:
{
  flake.aspects.services.ssh.nixos =
    { ... }:
    {
      # sops-nix derives the host age identity from the SSH host key; losing
      # /etc/ssh makes all secrets permanently unreadable.
      persistentDirectories = [ "/etc/ssh" ];

      services.openssh = {
        enable = true;
        # Firewall is opened per-interface below instead.
        openFirewall = false;

        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          X11Forwarding = false;
          Ciphers = [
            "chacha20-poly1305@openssh.com"
            "aes256-gcm@openssh.com"
          ];
          Macs = [
            "hmac-sha2-512-etm@openssh.com"
            "hmac-sha2-256-etm@openssh.com"
          ];
          KexAlgorithms = [
            "sntrup761x25519-sha512@openssh.com"
            "curve25519-sha256"
            "curve25519-sha256@libssh.org"
          ];
        };
      };

      # SSH is only reachable via the Tailscale interface.
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];
    };
}
