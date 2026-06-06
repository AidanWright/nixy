{
  ...
}:
{
  flake.modules.nixos.jonathan =
    { pkgs, ... }:
    {
      #imports = with inputs.self.modules.nixos; [
      ###
      #];
      networking.hostName = "jonathan";

      environment.systemPackages = with pkgs; [
        git
      ];

      services.tailscale.enable = true;

    };
}
