# modules/services/blog.nix
################################################################################
# Astro static blog built with buildNpmPackage and served by nginx at the apex domain.
# https://astro.build/
#
# www redirects to the apex.
################################################################################
{ inputs, ... }:
{
  flake.aspects.services.blog.nixos =
    { pkgs, ... }:
    let
      blogSite = pkgs.buildNpmPackage {
        pname = "aidanwright-blog";
        version = "0.1.0";

        src = inputs.self + "/blog";

        npmDepsHash = "sha256-h/Kt89+bdYsB55/VbbUGGh5LQBo5HSarCpzXQOz9YW0=";

        installPhase = ''
          mkdir -p $out
          cp -r dist/* $out/
        '';
      };
    in
    {
      services.nginx.virtualHosts = {
        "aidanwright.dev" = {
          forceSSL = true;
          enableACME = true;
          root = "${blogSite}";
        };

        "www.aidanwright.dev" = {
          forceSSL = true;
          enableACME = true;
          globalRedirect = "aidanwright.dev";
        };
      };
    };
}
