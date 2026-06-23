# modules/system/basic/admin.nix
################################################################################
# Foundational hidden `admin` account (ERNW guide: admin/standard separation).
# It is a HIDDEN, HOME-LESS, SHELL-ONLY account you escalate to (`su admin`) for
# privileged work — not a GUI/desktop user. It is created on every darwin host
# (included by `basic`) and put in the admin group (which grants sudo).
#
# v1: nix-darwin can't set passwords or grant Secure Tokens, so finish ONCE by
# hand as the current admin:
#   sudo dscl . -passwd /Users/admin '<strong-password>'
#   sudo sysadminctl -secureTokenOn admin -password - -adminUser aidanwright -adminPassword -
#   sudo sysadminctl -secureTokenStatus admin            # MUST say ENABLED
# Only after `su admin` + `sudo` work AND it has a Secure Token, demote the daily
# account: `sudo dscl . -delete /Groups/admin GroupMembership aidanwright`.
#
# Note: home is /var/empty (no home dir), which is fine for su/sudo but means
# `admin` can't itself run `darwin-rebuild` (nix needs a writable $HOME). Give it
# a real home (/Users/admin + createHome) if you ever want rebuilds to run as it.
################################################################################
{ ... }:
{
  flake.aspects.admin.darwin =
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
        home = "/var/empty";
        createHome = false;
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
