# modules/programs/vscode/latex.nix
################################################################################
# LaTeX authoring profile. The latexmk recipe matches the one code-server runs
# on biggy (services/web/latex/code-server.nix), so the same document builds the
# same way whether it is edited locally or over Tailscale.
#
# Building needs latexmk on PATH; no TeX distribution is installed by this
# aspect.
################################################################################
{ ... }:
{
  flake.aspects =
    { aspects, ... }:
    {
      programs.vscode.latex = {
        includes = with aspects; [ programs.vscode.base ];

        homeManager =
          { pkgs, ... }:
          {
            vscodeProfiles.latex = {
              extensions = with pkgs.nix-vscode-extensions.open-vsx; [
                james-yu.latex-workshop
                streetsidesoftware.code-spell-checker
              ];

              userSettings = {
                # Mirrors the recipe in services/web/latex/code-server.nix so a
                # document builds identically here and on biggy.
                "latex-workshop.latex.outDir" = "%DIR%";
                "latex-workshop.latex.recipe.default" = "lastUsed";
                "latex-workshop.latex.recipes" = [
                  {
                    name = "latexmk";
                    tools = [ "latexmk" ];
                  }
                ];
                "latex-workshop.latex.tools" = [
                  {
                    name = "latexmk";
                    command = "latexmk";
                    args = [
                      "-synctex=1"
                      "-interaction=nonstopmode"
                      "-file-line-error"
                      "-pdf"
                      "-outdir=%OUTDIR%"
                      "%DOC%"
                    ];
                  }
                ];
                "latex-workshop.view.pdf.viewer" = "tab";

                # Build artefacts sit beside the source because outDir is %DIR%;
                # hiding them keeps the explorer readable.
                "files.exclude" = {
                  "**/*.aux" = true;
                  "**/*.bbl" = true;
                  "**/*.blg" = true;
                  "**/*.fdb_latexmk" = true;
                  "**/*.fls" = true;
                  "**/*.lof" = true;
                  "**/*.lot" = true;
                  "**/*.out" = true;
                  "**/*.synctex.gz" = true;
                  "**/*.toc" = true;
                };

                "[latex]" = {
                  "editor.wordWrap" = "on";
                  "editor.wordWrapColumn" = 100;
                  "editor.quickSuggestions" = {
                    comments = false;
                    other = true;
                    strings = false;
                  };
                };

                "cSpell.language" = "en";
                "cSpell.enableFiletypes" = [
                  "latex"
                  "bibtex"
                ];
              };
            };
          };
      };
    };
}
