# modules/services/blog-cms.nix
################################################################################
# Sveltia CMS is a git-based headless CMS served at /admin on aidanwright.dev.
# https://github.com/sveltia/sveltia-cms
#
# The bundle is vendored as a fetchurl-pinned file and served by nginx; no
# server-side OAuth proxy is needed because the Forgejo backend uses PKCE
# (client-side only; no client secret required).
#
# One-time Forgejo setup: create an OAuth2 application with the redirect URI
# https://aidanwright.dev/admin/ and "Confidential Client" unchecked, then set
# the resulting Client ID as `blog.cms.forgejoAppId`.
#
# Disabled by default. Enable with:
#   blog.cms.enable = true;
#   blog.cms.forgejoAppId = "<client-id-from-forgejo>";
################################################################################
{ ... }:
{
  flake.aspects.services.blog-cms.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      options = {
        blog.cms = {
          enable = lib.mkEnableOption "Sveltia CMS admin panel at /admin";

          forgejoAppId = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "OAuth2 Client ID from the Forgejo application (required when CMS is enabled).";
          };
        };
      };

      sveltiaBundle = pkgs.fetchurl {
        url = "https://unpkg.com/@sveltia/cms@0.172.2/dist/sveltia-cms.js";
        hash = "sha256-5DXmTf6J7fuApfNnolukPRmlcJ5/7DGmSiA2+k4baPU=";
      };

      adminIndexHtml = pkgs.writeText "sveltia-cms-index.html" ''
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8" />
            <meta name="robots" content="noindex" />
            <title>Blog CMS</title>
          </head>
          <body>
            <script src="/admin/sveltia-cms.js"></script>
          </body>
        </html>
      '';

      adminConfigYml = pkgs.writeText "sveltia-cms-config.yml" ''
        backend:
          name: gitea
          repo: aidanwright/blog
          base_url: https://git.aidanwright.dev
          api_root: https://git.aidanwright.dev/api/v1
          branch: main
          app_id: ${config.blog.cms.forgejoAppId}

        media_folder: public/media
        public_folder: /media

        collections:
          - name: blog
            label: Blog
            label_singular: Post
            folder: src/content/blog
            create: true
            slug: "{{slug}}"
            fields:
              - { label: Title, name: title, widget: string }
              - { label: Date, name: date, widget: datetime, format: "YYYY-MM-DD", date_format: "YYYY-MM-DD", time_format: false }
              - { label: Description, name: description, widget: string }
              - { label: Tags, name: tags, widget: list, default: [] }
              - { label: Body, name: body, widget: markdown }

          - name: projects
            label: Projects
            label_singular: Project
            folder: src/content/projects
            create: true
            slug: "{{slug}}"
            fields:
              - { label: Title, name: title, widget: string }
              - { label: Date, name: date, widget: datetime, format: "YYYY-MM-DD", date_format: "YYYY-MM-DD", time_format: false }
              - { label: Description, name: description, widget: string }
              - { label: Tags, name: tags, widget: list, default: [] }
              - { label: Body, name: body, widget: markdown }
      '';

      adminDir = pkgs.runCommand "sveltia-cms-admin" { } ''
        mkdir -p $out
        cp ${adminIndexHtml} $out/index.html
        cp ${adminConfigYml} $out/config.yml
        cp ${sveltiaBundle} $out/sveltia-cms.js
      '';
    in
    {
      inherit options;

      config = lib.mkIf config.blog.cms.enable {
        services.nginx.virtualHosts."aidanwright.dev".locations = {
          "/admin/" = {
            alias = "${adminDir}/";
            index = "index.html";
          };
        };
      };
    };
}
