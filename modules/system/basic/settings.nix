# modules/system/basic/settings.nix
################################################################################
# Basic system settings: power management, input devices, privacy, and search.
################################################################################
{ ... }:
{
  flake.aspects =
    { aspects, ... }:
    {
      basic.settings = {
        includes = with aspects; [ options.base ];

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
            };

            system.defaults.hitoolbox.AppleFnUsageType = "Show Emoji & Symbols";
          };
      };
    };
}
