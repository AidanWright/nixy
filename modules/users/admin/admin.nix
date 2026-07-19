# modules/users/admin/admin.nix
################################################################################
# Assuming admin is not the default account, nix-darwin cannot set passwords or grant Secure Tokens,
# so finish by hand as the current admin:
#   sudo dscl . -passwd /Users/admin '<strong-password>'
#   sudo sysadminctl -secureTokenOn admin -password - -adminUser aidanwright -adminPassword -
#   sudo sysadminctl -secureTokenStatus admin            # MUST say ENABLED
# Only after `su - admin` + `sudo` + `darwin-rebuild` work AND it has a Secure
# Token, demote the daily account:
#   sudo dscl . -delete /Groups/admin GroupMembership aidanwright
#
# nix-darwin refuses to move an existing user's home. If this account already
# exists with a different home, migrate it by hand BEFORE rebuilding:
#   sudo dscl . -create /Users/admin NFSHomeDirectory /Users/admin
#   sudo createhomedir -c -u admin
################################################################################
{ inputs, ... }:
{
  flake.aspects.users.admin.darwin =
    {
      pkgs,
      lib,
      ...
    }:
    {
      imports = [ (inputs.self.lib.useFish "admin") ];

      users.knownUsers = [ "admin" ];
      users.users.admin = {
        uid = 540;
        gid = 20; # staff
        name = "admin";
        home = "/Users/admin";
        createHome = true;
        isHidden = true;
        shell = pkgs.fish;
        description = "Local Administrator";
      };

      home-manager.users.admin =
        { lib, ... }:
        {
          imports = [
            inputs.self.modules.homeManager."programs.bat"
            inputs.self.modules.homeManager."programs.starship"
            inputs.self.modules.homeManager."programs.eza"
          ];
          home.stateVersion = "26.05";

          # Label the prompt with a bold red [ADMIN] tag so an escalated admin
          # shell is unmistakable, keeping the segment's usual orange fill.
          local.starshipExtraLine = "[!!  ADMIN SHELL !!](bold italic fg:color_red) ";
        };

      # nix-darwin has no admin-group option; grant sudo idempotently.
      system.activationScripts.postActivation.text = lib.mkAfter ''
        if ! /usr/sbin/dseditgroup -o checkmember -m admin admin >/dev/null 2>&1; then
          /usr/sbin/dseditgroup -o edit -a admin -t user admin || true
        fi
      '';

      # Needed for admin can activate nix-darwin builds, assuming not already the owner.
      environment.etc."gitconfig".text = ''
        [safe]
        	directory = /private/etc/nix-darwin
        	directory = /etc/nix-darwin
      '';
    };
}
