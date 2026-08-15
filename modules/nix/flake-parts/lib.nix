# modules/nix/flake-parts/lib.nix
################################################################################
# Exports mkNixos, mkDarwin, and mkHomeManager helpers via flake.lib.
# https://github.com/Doc-Steve/dendritic-design-with-flake-parts/blob/main/modules/nix/flake-parts%20%5B%5D/lib.nix#L25
################################################################################
{
  inputs,
  lib,
  ...
}:
{
  options.flake.lib = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = { };
  };

  config.flake.lib = {

    mkNixos = system: name: {
      ${name} = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          inputs.self.modules.nixos.${name}
          inputs.self.modules.nixos."overlays.unstable"
          inputs.self.modules.nixos."overlays.master"
          inputs.self.modules.nixos."options.all"
          inputs.self.modules.nixos."minimal.base"
          { nixpkgs.hostPlatform = lib.mkDefault system; }
        ];
      };
    };

    mkHomeManager = system: name: extraModules: {
      ${name} = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        modules = [
          inputs.self.modules.homeManager.${name}
          inputs.self.modules.homeManager."overlays.unstable"
          inputs.self.modules.homeManager."overlays.master"
        ]
        ++ extraModules;
      };
    };

    mkDarwin = system: name: {
      ${name} = inputs.nix-darwin.lib.darwinSystem {
        modules = [
          inputs.self.modules.darwin.${name}
          inputs.self.modules.darwin."overlays.unstable"
          inputs.self.modules.darwin."overlays.master"
          inputs.self.modules.darwin."overlays.darwin-apps"
          inputs.self.modules.darwin."minimal.base"
          inputs.self.modules.darwin."security.all"
          inputs.self.modules.darwin."homebrew"
          inputs.self.modules.darwin."home-manager"
          { home-manager.sharedModules = [ inputs.self.modules.homeManager."security.sops" ]; }
          { nixpkgs.hostPlatform = lib.mkDefault system; }
        ];
      };
    };

    tailscaleOnlyPorts =
      {
        tcp ? [ ],
        udp ? [ ],
      }:
      {
        networking.firewall.interfaces.tailscale0 = {
          allowedTCPPorts = tcp;
          allowedUDPPorts = udp;
        };
      };

    # Builds the AppArmor profile for one systemd service and attaches it.
    # Everything not granted is denied: an AppArmor profile is deny-by-default
    # once it applies, so a profile only has to list what the service needs.
    #
    # `packages`, `exec` and `rules` are functions of the module arguments
    # rather than plain values, because the result is used from `imports`,
    # which cannot depend on `config` without causing infinite recursion.
    mkServiceProfile =
      {
        name,
        unit ? name,
        packages ? (_: [ ]),
        # Closure rules cost roughly ten lines per store path, and the parser
        # recompiles them on every boot. A unit whose path carries something
        # very large sets this false and names its entry points in `rules` instead.
        includeUnitPath ? true,
        abstractions ? [
          "base"
          "nameservice"
        ],
        rules ? (_: ""),
        enable ? (_: true),
      }:
      moduleArgs@{
        config,
        lib,
        pkgs,
        ...
      }:
      let
        service = config.systemd.services.${unit};

        # systemd permits a leading "-", "@", "+", "!" or ":" and arguments
        # after the binary, so the path is the first token once those are cut.
        execBinary =
          line:
          let
            token = builtins.match "[-@+!:]*([^[:space:]]+).*" line;
          in
          if token == null then null else lib.head token;

        execPaths = lib.unique (
          lib.filter (path: path != null && lib.hasPrefix builtins.storeDir path) (
            map execBinary (
              lib.concatMap (key: lib.toList (service.serviceConfig.${key} or [ ])) [
                "ExecStart"
                "ExecStartPre"
                "ExecStartPost"
                "ExecStop"
                "ExecStopPost"
                "ExecReload"
              ]
            )
          )
        );

        # Units usually start a generated wrapper script that only references
        # the service package, so it is absent from that package's closure.
        # Reading the paths off the unit is what lets a profile enforce at all.
        closureRoots =
          packages moduleArgs ++ lib.optionals includeUnitPath (lib.filter lib.isDerivation service.path);
      in
      lib.mkIf (enable moduleArgs) {
        assertions = [
          {
            assertion = execPaths != [ ];
            message = "mkServiceProfile: systemd unit '${unit}' declares no Exec* in the store; check the unit name.";
          }
        ];

        security.apparmor.policies.${name} = {
          state = lib.mkDefault config.apparmorDefaultState;

          # The profile is named rather than attached to a path. systemd enters
          # it by name via AppArmorProfile=, so nothing here has to match a
          # /nix/store path that changes on every rebuild — the problem that
          # otherwise forces store globs and the rule conflicts they cause.
          # attach_disconnected is required because the systemd sandboxing these
          # services also use leaves parts of the mount tree unreachable by path.
          profile = ''
            abi <abi/4.0>,
            include <tunables/global>

            profile ${name} flags=(attach_disconnected) {
              ${lib.concatMapStringsSep "\n  " (a: "include <abstractions/${a}>") abstractions}
              include <local/nix-store>
              include "${
                pkgs.apparmorRulesFromClosure {
                  inherit name;
                  # The default rules cover libraries and libexec but not bin,
                  # so without this a service cannot execute its own helpers.
                  # These stay literal store paths, one set per closure entry,
                  # so they never become a glob over the whole store.
                  additionalRules = [
                    "$path/bin/** ixr"
                    "$path/sbin/** ixr"
                  ];
                } closureRoots
              }"

              ${lib.concatMapStringsSep "\n  " (path: "${path} ixr,") execPaths}

              ${rules moduleArgs}

              include if exists <local/${name}>
            }
          '';
        };

        # While a profile is still in complain mode the leading `-` keeps a
        # failed transition from stopping the service
        systemd.services.${unit}.serviceConfig.AppArmorProfile = lib.mkIf config.security.apparmor.enable (
          if config.security.apparmor.policies.${name}.state == "enforce" then name else "-${name}"
        );
      };

  };
}
