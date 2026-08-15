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
      ...
    }:
    let
      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
    in
    {
      imports = [ inputs.mcp-servers-nix.homeManagerModules.default ];

      home.packages = lib.optionals isDarwin [ pkgs.darwinApps.claude-desktop ];

      mcp-servers.programs = {
        nixos.enable = true; # live nixpkgs/option search; fresher than a pinned `nix search`
        playwright.enable = true; # real browser for JavaScript-heavy or anti-scraping sites
      };

      programs.mcp.enable = true;

      programs.claude-code = {
        enable = true;
        enableMcpIntegration = true;
        package = inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };
    };
}
