# modules/hosts/macbook-pro/configuration.nix
################################################################################
# macbook-pro host configuration.
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
          dev.all
          services.tailscale
          programs.all
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
