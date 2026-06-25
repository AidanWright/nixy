# modules/programs/claude.nix
################################################################################
# Claude tooling. The claude-code CLI (from sadjow/claude-code-nix) with
# pre-configured MCP servers ships as a home-manager aspect; the Claude desktop
# app ships as a system Homebrew cask.
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

  flake.aspects.programs.claude = {
    homeManager =
      { pkgs, ... }:
      {
        imports = [ inputs.mcp-servers-nix.homeManagerModules.default ];

        mcp-servers.programs = {
          filesystem = {
            enable = true;
            args = [
              "/etc/nix-darwin"
              "/Users/aidanwright/Library/CloudStorage/ZohoWorkDriveTrueSync-AidanWright/General/Code"
            ];
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

    darwin =
      { ... }:
      {
        homebrew.casks = [ "claude" ];
      };
  };
}
