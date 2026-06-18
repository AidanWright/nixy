# modules/system/basic.nix
################################################################################
# Basic system settings: power management, input devices, privacy, and search.
################################################################################
{ ... }:
{
  flake.aspects =
    {
      aspects,
      ...
    }:
    {
      basic = {
        includes = with aspects; [
          darwin-options
          determinate
          homebrew
          home-manager
          stylix
        ];

        darwin =
          { ... }:
          {
            power.sleep = {
              display = 5;
              computer = 10;
              harddisk = 5;
            };

            darwin = {
              trackpad = {
                tapToClick = true;
                secondaryClick = true;
                forceClick = true;
                clickPressure = "medium";
                lookUpGesture = "forceClick";
                trackingSpeed = 1.0;
              };

              keyboard = {
                navigation = true;
                brightnessInLowLight = true;
                dimAfterSeconds = 30;
              };

              spotlight = {
                showRelatedContent = true;
                helpImproveSearch = false;
                enabledCategories = [
                  "applications"
                  "books"
                  "calculator"
                  "calendar"
                  "contacts"
                  "definitions"
                  "mail"
                  "messages"
                  "notes"
                  "music"
                  "movies"
                  "systemSettings"
                  "websites"
                  "developer"
                ];
              };

              siri = {
                enable = false;
                enableAppleIntelligence = false;
              };
            };

            system.defaults.hitoolbox.AppleFnUsageType = "Show Emoji & Symbols";

            networking.applicationFirewall = {
              enable = true;
              allowSignedApp = true;
            };
          };
      };
    };
}
