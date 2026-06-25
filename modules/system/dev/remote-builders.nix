# modules/system/dev/remote-builders.nix
################################################################################
# Configures nixbuild.net as a remote builder.
################################################################################
{ ... }:
let
  sshConfig = ''
    Host eu.nixbuild.net
      PubkeyAcceptedKeyTypes ssh-ed25519
      ServerAliveInterval 60
      IdentityFile /etc/nix/builder_key
      SetEnv NIXBUILDNET_KEEP_BUILDS_RUNNING=true NIXBUILDNET_REUSE_BUILD_FAILURES=false
  '';

  knownHost = {
    hostNames = [ "eu.nixbuild.net" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
  };

  machinesFile = ''
    ssh://eu.nixbuild.net x86_64-linux - 100 1 benchmark,big-parallel
  '';

  builderSettings = {
    builders = "@/etc/nix/machines";
    builders-use-substitutes = true;
  };
in
{
  flake.aspects.dev.remote-builders.darwin =
    { config, lib, ... }:
    lib.mkMerge [
      {
        programs.ssh.extraConfig = sshConfig;
        programs.ssh.knownHosts.nixbuild = knownHost;
        environment.etc."nix/machines".text = machinesFile;
      }
      (lib.mkIf config.determinateNix.enable { determinateNix.customSettings = builderSettings; })
      (lib.mkIf (!config.determinateNix.enable) { nix.settings = builderSettings; })
    ];

  flake.aspects.dev.remote-builders.nixos =
    { ... }:
    {
      programs.ssh.extraConfig = sshConfig;
      programs.ssh.knownHosts.nixbuild = knownHost;
      environment.etc."nix/machines".text = machinesFile;
      nix.settings = builderSettings;
    };
}
