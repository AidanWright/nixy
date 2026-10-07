# modules/system/security/luks.nix
################################################################################
# https://wiki.nixos.org/wiki/Remote_disk_unlocking
# Unlocks the LUKS root at boot. Clevis answers systemd's password prompt from a
# Tang server; an initrd SSH daemon on port 2222 takes over when Tang is
# unreachable, and the console passphrase prompt remains as the last resort.
#
# The Tang binding lives in the LUKS2 header, not here. Bind after the first
# boot, passing a thumbprint fetched over a path you trust:
#   clevis luks bind -d /dev/<part> tang '{"url":"https://...","thp":"<thumb>"}'
#
# The initrd host key is appended to an initrd that sits on the unencrypted ESP,
# so it is a throwaway distinct from the sops host identity. Create it before
# provisioning, alongside the sops key (see nix/tools/remote-deploy.nix):
#   ssh-keygen -t ed25519 -N "" -f <persist>/etc/secrets/initrd/ssh_host_ed25519_key
#
# Unlock by hand with:
#   ssh -p 2222 root@<host>   then   systemd-tty-ask-password-agent
################################################################################
{ ... }:
{
  flake.aspects.security.luks.nixos =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      caBundle = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

      initrdHostKey = "/etc/secrets/initrd/ssh_host_ed25519_key";

      loginKeys = lib.concatMap (user: user.openssh.authorizedKeys.keys) (
        lib.filter (user: user.isNormalUser) (lib.attrValues config.users.users)
      );
    in
    {
      environment.systemPackages = [ pkgs.clevis ];

      boot.initrd.systemd.network.enable = true;
      boot.kernelParams = [ "ip=dhcp" ];

      boot.initrd.network.ssh = {
        enable = true;
        port = 2222;
        hostKeys = [ initrdHostKey ];
        authorizedKeys = loginKeys;
      };

      boot.initrd.clevisLuksAskpass = {
        enable = true;
        useTang = true;
      };

      # The clevis initrd ships curl but no trust store, and Tang is reached
      # over the HTTPS endpoint Tailscale Funnel publishes.
      boot.initrd.systemd = {
        storePaths = [ caBundle ];

        # Reaching the prompt over SSH needs the agent on PATH; systemd stage 1
        # ships only a small set of binaries in /bin.
        extraBin.systemd-tty-ask-password-agent = "${config.boot.initrd.systemd.package}/bin/systemd-tty-ask-password-agent";

        services.clevis-luks-askpass.environment = {
          CURL_CA_BUNDLE = caBundle;
          SSL_CERT_FILE = caBundle;
        };
      };

      persistentFiles = [ initrdHostKey ];
    };
}
