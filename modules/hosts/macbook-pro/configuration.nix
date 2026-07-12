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
          basic.all
          determinate
          homebrew
          home-manager
          hardening
          overlays.darwin-apps
          dev.all
          services.tailscale
          programs.all
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
