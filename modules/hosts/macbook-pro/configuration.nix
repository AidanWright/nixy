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
          services.tailscale
          programs.all
          dev.all

          ##
          users.admin
          users.aidanwright
        ];

        darwin =
          { ... }:
          {
            networking.hostName = "macbook-pro";
            system.primaryUser = "aidanwright";
          };
      };
    };
}
