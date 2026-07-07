# modules/programs/safari.nix
################################################################################
# Hardens Safari, the browser Finicky hands streaming sites to, with the uBlock
# Origin Lite content blocker and a privacy Configuration Profile.
#
# Safari's prefs live in a SIP-protected sandbox `defaults` cannot write, and
# macOS 11+ dropped CLI profile installs, so the profile is generated here but
# installed once by hand: open ~/.config/nix-darwin/Safari-Privacy.mobileconfig
# and approve it in System Settings. Enabling the extension is likewise a manual
# Safari toggle -- only supervised MDM devices can force that.
################################################################################
{ ... }:
let
  safariPrivacyProfile = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>PayloadContent</key>
      <array>
        <dict>
          <key>PayloadType</key>
          <string>com.apple.Safari</string>
          <key>PayloadVersion</key>
          <integer>1</integer>
          <key>PayloadIdentifier</key>
          <string>dev.aidanwright.safari.privacy.settings</string>
          <key>PayloadUUID</key>
          <string>20795BAB-8888-44EA-8D38-47C193FF1121</string>
          <key>PayloadDisplayName</key>
          <string>Safari Privacy Settings</string>
          <key>SuppressSearchSuggestions</key>
          <true/>
          <key>UniversalSearchEnabled</key>
          <false/>
          <key>WebKitPreferences.privateClickMeasurementEnabled</key>
          <false/>
          <key>WarnAboutFraudulentWebsites</key>
          <true/>
          <key>ShowFullURLInSmartSearchField</key>
          <true/>
          <key>EnableEnhancedPrivacyInRegularBrowsing</key>
          <true/>
          <key>EnableEnhancedPrivacyInPrivateBrowsing</key>
          <true/>
        </dict>
      </array>
      <key>PayloadType</key>
      <string>Configuration</string>
      <key>PayloadVersion</key>
      <integer>1</integer>
      <key>PayloadIdentifier</key>
      <string>dev.aidanwright.safari.privacy</string>
      <key>PayloadUUID</key>
      <string>C31E6D63-A746-4466-9BE3-EFD8370F27B6</string>
      <key>PayloadDisplayName</key>
      <string>Safari Privacy</string>
      <key>PayloadDescription</key>
      <string>Enables advanced fingerprinting protection for all browsing and disables Safari search telemetry and ad click measurement.</string>
      <key>PayloadScope</key>
      <string>User</string>
      <key>PayloadOrganization</key>
      <string>nix-darwin</string>
    </dict>
    </plist>
  '';
in
{
  flake.aspects.programs.safari.darwin =
    { config, ... }:
    {
      # Full uBlock Origin does not exist for Safari; uBlock Origin Lite (its MV3
      # build, by the same author) is the closest option and ships only through
      # the App Store, so mas installs it -- which needs an App Store sign-in.
      homebrew.masApps."uBlock Origin Lite" = 6745342698;

      home-manager.users.${config.system.primaryUser}.home.file.".config/nix-darwin/Safari-Privacy.mobileconfig".text =
        safariPrivacyProfile;
    };
}
