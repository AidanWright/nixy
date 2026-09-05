# modules/system/dev/esp-idf.nix
################################################################################
# ESP-IDF Installation Manager and the prerequisites it expects. EIM installs
# ESP-IDF itself. Also needs `xcode-select --install`.
################################################################################
{ inputs, ... }:
{
  flake-file.inputs.homebrew-eim = {
    url = "github:espressif/homebrew-eim";
    flake = false;
  };

  flake.aspects.dev.esp-idf.darwin =
    { pkgs, ... }:
    {
      nix-homebrew.taps."espressif/homebrew-eim" = inputs.homebrew-eim;
      nix-homebrew.trust.taps = [ "espressif/eim" ];
      homebrew.casks = [ "eim-gui" ];

      environment.systemPackages = with pkgs; [
        ninja
        ccache

      ];

      # QEMU support, per the cask's caveats. Espressif's prebuilt tools load
      # these from /opt/homebrew by absolute path, so a nixpkgs build of the
      # same library is never consulted.
      homebrew.brews = [
        "dfu-util"
        "cmake"
        "libgcrypt"
        "glib"
        "pixman"
        "sdl2"
        "libslirp"
        "python"
      ];
    };
}
