# modules/programs/cli/gpg.nix
################################################################################
# GnuPG set up for a YubiKey-backed OpenPGP signing key (the key referenced by
# programs.git.signing). Enables gpg + a local gpg-agent with a
# platform-appropriate pinentry, and ships `ykman` for managing the key.
#
# The card reader is system-level, not home-manager: on a Linux host install
# pcscd and the yubikey udev rules. WSL has no smart-card access of its own, so
# the `programs.gpg-wsl` aspect replaces this local agent with a bridge to the
# Windows (Gpg4win) gpg-agent instead.
################################################################################
{ ... }:
{
  flake.aspects.programs.gpg.homeManager =
    { pkgs, lib, ... }:
    {
      programs.gpg.enable = true;

      services.gpg-agent = {
        # mkDefault so `programs.gpg-wsl` can disable this local agent and hand
        # signing off to the Windows host agent instead.
        enable = lib.mkDefault true;
        # curses pinentry works headlessly (WSL/SSH); macOS gets the GUI prompt.
        pinentry.package =
          if pkgs.stdenv.hostPlatform.isDarwin then pkgs.pinentry_mac else pkgs.pinentry-curses;
      };

      # ykman: inspect and configure the YubiKey (PIN, touch policy, key slots).
      home.packages = [ pkgs.yubikey-manager ];
    };
}
