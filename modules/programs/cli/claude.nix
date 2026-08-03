# modules/programs/cli/claude.nix
################################################################################
# Claude tooling, scoped to the user that imports it. The claude-code CLI (from
# sadjow/claude-code-nix) ships with pre-configured MCP servers, and the Claude
# desktop app is installed from its official release via pkgs.darwinApps.
################################################################################
{ inputs, ... }:
{
  flake-file.inputs = {
    claude-code-nix.url = "github:sadjow/claude-code-nix";
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  flake.aspects.programs.claude.homeManager =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

      filesystemRoots =
        if isDarwin then
          [
            "/etc/nix-darwin"
            "/Users/aidanwright/Library/CloudStorage/ZohoWorkDriveTrueSync-AidanWright/General/Code"
          ]
        else
          [ config.home.homeDirectory ];
    in
    {
      imports = [ inputs.mcp-servers-nix.homeManagerModules.default ];

      home.packages = lib.optionals isDarwin [ pkgs.darwinApps.claude-desktop ];

      mcp-servers.programs = {
        filesystem = {
          enable = true;
          args = filesystemRoots;
        };
        fetch.enable = true;
        git.enable = true;
        memory.enable = true;
        sequential-thinking.enable = true;
        nixos.enable = true;
      };

      programs.mcp.enable = true;

      programs.claude-code = {
        enable = true;
        enableMcpIntegration = true;
        package = inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };
    };
}
