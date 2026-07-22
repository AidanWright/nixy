# tests/biggy-e2e.nix
################################################################################
# Hermetic NixOS VM smoke test for the biggy server configuration.
# Boots a QEMU guest with biggy's service and hardening aspects, then asserts
# that the key services start and respond on their expected ports.
#
# Uses biggy's own fully-configured nixpkgs (allowUnfree + all overlays) as the
# node pkgs, so the node need not import the overlay/config aspects (which would
# conflict with the nixosTest framework's read-only nixpkgs).
#
# Excluded vs. the real biggy host:
#   - security.impermanence  (tmpfs root conflicts with the test VM disk)
#   - services.blog          (buildNpmPackage fetches the network)
#   - services.tailscale     (needs a real tailnet + sops-encrypted auth key)
#   - services.code-server   (its `includes` pulls an overlay module that
#                             re-sets nixpkgs.overlays -> read-only conflict)
#   - disko / grub / efi     (host-level disk layout; the test driver owns that)
#
# Run on an aarch64-linux host with KVM (the biggy VM at port 2222):
#   cd ~/nix-darwin && nix build --impure -f tests/biggy-e2e.nix -L
################################################################################
let
  flake = builtins.getFlake "path:/home/nixos/nix-darwin";
  pkgs = flake.nixosConfigurations.biggy.pkgs;
  lib = pkgs.lib;
in
pkgs.testers.runNixOSTest {
  name = "biggy-e2e";

  nodes.machine =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        flake.modules.nixos."security.hardening"
        flake.modules.nixos."security.sops"
        flake.modules.nixos."persistence"

        flake.modules.nixos."services.ssh"
        flake.modules.nixos."services.fail2ban"
        flake.modules.nixos."services.crowdsec"
        flake.modules.nixos."services.chrony"
        flake.modules.nixos."services.resolved"
        flake.modules.nixos."services.netdata"
        flake.modules.nixos."services.honeypot"
        flake.modules.nixos."services.nginx"
        flake.modules.nixos."services.forgejo"
        flake.modules.nixos."services.syncthing"
        flake.modules.nixos."services.homepage-dashboard"
        flake.modules.nixos."services.uptime-kuma"

        flake.modules.nixos."users.aidanwright"
      ];

      # minimal.base essentials (imported directly instead of the whole aspect,
      # which sets read-only nixpkgs.config):
      system.stateVersion = "26.05";
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      # ---- neutralize secrets / tailscale ----------------------------------
      sops.secrets = lib.mkForce { };
      sops.age.sshKeyPaths = lib.mkForce [ ];
      services.tailscale.enable = lib.mkForce false;

      # ---- neutralize ACME (no CA reachable in the hermetic VM) ------------
      # Override the known public vhosts to plain HTTP so nginx starts without
      # requesting a Let's Encrypt certificate. (blog's apex/www vhosts aren't
      # imported in this cut.)
      services.nginx.virtualHosts."frame.aidanwright.dev" = {
        forceSSL = lib.mkForce false;
        enableACME = lib.mkForce false;
      };
      services.nginx.virtualHosts."git.aidanwright.dev" = {
        forceSSL = lib.mkForce false;
        enableACME = lib.mkForce false;
      };
      security.acme.acceptTerms = true;

      virtualisation = {
        memorySize = 2048;
        diskSize = 8192;
        cores = 1;
      };

      networking.hostName = lib.mkForce "biggy";
    };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target", timeout=600)

    machine.wait_for_unit("nginx.service", timeout=120)
    machine.wait_for_unit("forgejo.service", timeout=120)
    machine.wait_for_unit("netdata.service", timeout=120)
    machine.wait_for_unit("sshd.service", timeout=60)

    machine.wait_for_open_port(3000, timeout=120)
    machine.succeed("curl -sf http://127.0.0.1:3000/ >/dev/null")

    # nginx reverse-proxies git.aidanwright.dev -> forgejo:3000 on :80.
    machine.wait_for_open_port(80, timeout=60)
    machine.succeed("curl -sf -H 'Host: git.aidanwright.dev' http://127.0.0.1/ >/dev/null")

    machine.wait_for_open_port(19999, timeout=60)

    machine.succeed("sshd -T | grep -i 'permitrootlogin no'")
    machine.succeed("sshd -T | grep -i 'passwordauthentication no'")

    print("=== failed units ===")
    print(machine.succeed("systemctl --failed --no-legend || true"))
  '';
}
