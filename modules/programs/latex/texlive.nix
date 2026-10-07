# modules/programs/latex/texlive.nix
################################################################################
# TeX Live for local document builds. Kept separate from the editor aspect so a
# host can carry the toolchain without VS Code, and so the scheme can be resized
# in one place.
################################################################################
{ ... }:
{
  flake.aspects.programs.latex.texlive.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        (pkgs.texlive.withPackages (
          ps: with ps; [
            scheme-medium
            latexmk
            latexindent
            biber
            enumitem
            sectsty
            titlesec
            libertinus-otf
            libertinus-fonts
          ]
        ))
      ];
    };
}
