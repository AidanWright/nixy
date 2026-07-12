# modules/system/basic/admin.nix
################################################################################
# Foundational hidden `admin` account (ERNW guide: admin/standard separation).
# It is a HIDDEN, HOME-LESS, SHELL-ONLY account you escalate to (`su admin`) for
# privileged work — not a GUI/desktop user. It is created on every darwin host
# (included by `basic`) and put in the admin group (which grants sudo).
#
# It has a real home (/Users/admin) so it can run `darwin-rebuild` itself once the
# daily account loses sudo (nix needs a writable $HOME).
#
# v1: nix-darwin can't set passwords or grant Secure Tokens, so finish ONCE by
# hand as the current admin:
#   sudo dscl . -passwd /Users/admin '<strong-password>'
#   sudo sysadminctl -secureTokenOn admin -password - -adminUser aidanwright -adminPassword -
#   sudo sysadminctl -secureTokenStatus admin            # MUST say ENABLED
# Only after `su admin` + `sudo` + `darwin-rebuild` work AND it has a Secure Token,
# demote the daily account: `sudo dscl . -delete /Groups/admin GroupMembership aidanwright`.
#
# nix-darwin refuses to move an existing user's home. If this account already
# exists with a different home, migrate it by hand BEFORE rebuilding:
#   sudo dscl . -create /Users/admin NFSHomeDirectory /Users/admin
#   sudo createhomedir -c -u admin
################################################################################
{ ... }:
{
  flake.aspects.basic.admin.darwin =
    {
      pkgs,
      lib,
      ...
    }:
    {
      users.knownUsers = [ "admin" ];
      users.users.admin = {
        uid = 540;
        gid = 20; # staff
        name = "admin";
        home = "/Users/admin";
        createHome = true;
        isHidden = true;
        shell = pkgs.zsh;
        description = "Local Administrator";
      };

      # nix-darwin has no admin-group option; grant sudo idempotently.
      system.activationScripts.postActivation.text = lib.mkAfter ''
        if ! /usr/sbin/dseditgroup -o checkmember -m admin admin >/dev/null 2>&1; then
          /usr/sbin/dseditgroup -o edit -a admin -t user admin || true
        fi
      '';
    };
}
