# modules/programs/librewolf.nix
################################################################################
# Configures the LibreWolf browser and a hardened default profile via home-manager.
# Declarative add-ons are pulled from the NUR `rycee.firefox-addons` set.
################################################################################
{ inputs, ... }:
{
  flake-file.inputs.nur = {
    url = "github:nix-community/NUR";
    inputs.nixpkgs.follows = "nixpkgs";
    # Without this, NUR pulls its own (identical) flake-parts node, which
    # nix-auto-follow collapses but nix re-expands — breaking check-flake-file.
    inputs.flake-parts.follows = "flake-parts";
  };

  flake.aspects.programs.librewolf.darwin =
    {
      config,
      pkgs,
      ...
    }:
    let
      # Sourced through the overlay rather than nur.legacyPackages so the host's
      # allowUnfree config applies; some add-ons (onetab) are unfree.
      firefoxAddons = pkgs.nur.repos.rycee.firefox-addons;

      browserExtensions = with firefoxAddons; [
        ublock-origin
        bitwarden
        clearurls
        dearrow
        onetab
        sponsorblock
      ];
    in
    {
      nixpkgs.overlays = [ inputs.nur.overlays.default ];

      # librewolf 151.0.2-1 carries an upstream advisory; the home-manager
      # profile uses the same build, so the allowance moves here with it.
      nixpkgs.config.permittedInsecurePackages = [
        "librewolf-151.0.2-1"
        "librewolf-unwrapped-151.0.2-1"
      ];

      home-manager.users.${config.system.primaryUser} = {
        stylix.targets.librewolf = {
          profileNames = [ "default" ];
          colorTheme.enable = true;
        };

        programs.librewolf = {
          enable = true;

          settings = {
            "browser.startup.homepage" = "about:home";
            "privacy.donottrackheader.enabled" = true;
            "privacy.resistFingerprinting" = true;
            "privacy.fingerprintingProtection" = true;
            "browser.contentblocking.category" = "strict";
            "network.prefetch-next" = false;
            # DNS-over-HTTPS forced through Quad9.
            "network.trr.mode" = 2;
            "network.trr.uri" = "https://dns.quad9.net/dns-query";
          };

          profiles.default = {
            id = 0;
            isDefault = true;

            settings = {
              "browser.toolbars.bookmarks.visibility" = "always";
              "browser.tabs.inTitlebar" = 1;

              # Wipe history and cookies on close. Firefox 128+ renamed these
              # from privacy.clearOnShutdown.* to the _v2 keys below.
              "privacy.sanitize.sanitizeOnShutdown" = true;
              "privacy.clearOnShutdown_v2.historyFormDataAndDownloads" = true;
              "privacy.clearOnShutdown_v2.cookiesAndStorage" = true;

              # RFP breaks colonist.io's WebGL board;
              # exempt just that origin. exemptedDomains is inert without the
              # testGranularityMask gate.
              "privacy.resistFingerprinting.exemptedDomains" = "colonist.io,*.colonist.io";
              "privacy.resistFingerprinting.testGranularityMask" = 4;
            };

            search = {
              force = true;
              default = "policy-Startpage";
              privateDefault = "policy-Startpage";
            };

            extensions = {
              # stylix' colorTheme writes Firefox Color settings into this
              # profile; force lets it own extension settings declaratively.
              force = true;
              packages = browserExtensions;
            };
          };
        };
      };
    };
}
