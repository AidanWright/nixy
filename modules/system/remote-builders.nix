# modules/system/remote-builders.nix
################################################################################
#
################################################################################
{ ... }:
{
  flake.modules.darwin.remoteBuilders =
    { ... }:
    {
      programs.ssh.extraConfig = ''
        Host eu.nixbuild.net
          PubkeyAcceptedKeyTypes ssh-ed25519
          ServerAliveInterval 60
          IdentityFile /etc/nix/builder_key
          SetEnv NIXBUILDNET_KEEP_BUILDS_RUNNING=true NIXBUILDNET_REUSE_BUILD_FAILURES=false
      '';

      programs.ssh.knownHosts = {
        nixbuild = {
          hostNames = [ "eu.nixbuild.net" ];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
        };
      };

      environment.etc."nix/machines".text = ''
        ssh://eu.nixbuild.net x86_64-linux - 100 1 benchmark,big-parallel
      '';

      determinateNix.customSettings = {
        builders = "@/etc/nix/machines";
        builders-use-substitutes = true;
      };
    };
}
