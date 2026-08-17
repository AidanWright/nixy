# modules/hosts/macbook-pro/configuration.nix
################################################################################
# macbook-pro host configuration.
# The included aspects define the features of the system.
# The .all keyword includes all sub-aspects.
################################################################################
{ ... }:
{
  flake.aspects =
    { aspects, ... }:
    {
      macbook-pro = {
        includes = with aspects; [
          determinate
          basic.all

          ##
          services.security.tailscale
          programs.all
          dev.all

          ##
          users.admin
          aidanwright
        ];

        darwin =
          { lib, ... }:
          {
            networking.hostName = "macbook-pro";
            system.primaryUser = "aidanwright";

            nix-homebrew.user = "admin";

            determinateNix.customSettings.sandbox = lib.mkForce "relaxed";
          };
      };
    };
}
