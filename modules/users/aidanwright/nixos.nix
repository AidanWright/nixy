# modules/users/aidanwright/nixos.nix
################################################################################
# https://search.nixos.org/options?query=users.users
# NixOS login account for aidanwright: wheel group, fish shell, key-only SSH.
################################################################################
{ ... }:
{
  flake.aspects.users.aidanwright.nixos =
    { pkgs, ... }:
    {
      # Home holds code-server data, the latex sync folder, dotfiles, and SSH
      # client config; all are lost on every boot without this.
      persistentDirectories = [ "/home/aidanwright" ];

      programs.fish.enable = true;

      users.users.aidanwright = {
        isNormalUser = true;
        description = "Aidan Wright";
        extraGroups = [ "wheel" ];
        shell = pkgs.fish;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII8kymY/zb/avbDXLvFE+U6S1jy0lsSrBBfQQ5hjKkdD mail@aidanwright.dev"
        ];
      };

      security.sudo.wheelNeedsPassword = false;
    };
}
