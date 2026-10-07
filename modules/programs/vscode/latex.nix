# modules/programs/vscode/latex.nix
################################################################################
# LaTeX authoring profile. Recipes cover lualatex, xelatex and pdflatex, with
# lualatex the fallback because fontspec refuses to run under pdflatex. A
# document can override per-file with a `% !TEX program = ...` magic comment.
#
# Pulls in programs.latex.texlive for latexmk and latexindent, which the build
# and format-on-save settings below both shell out to, and programs.latex.pdfname
# for the latexmk wrapper every recipe calls. The wrapper builds like latexmk
# until a document opts into naming its own PDF; see that aspect for the syntax.
################################################################################
{ ... }:
{
  flake.aspects =
    { aspects, ... }:
    {
      programs.vscode.latex = {
        includes = with aspects; [
          programs.vscode.base
          programs.latex.texlive
          programs.latex.pdfname
        ];

        homeManager =
          { pkgs, ... }:
          let
            engines = [
              {
                name = "lualatex";
                flag = "-lualatex";
              }
              {
                name = "xelatex";
                flag = "-xelatex";
              }
              {
                name = "pdflatex";
                flag = "-pdf";
              }
            ];

            latexmkTool = engine: {
              name = "latexmk (${engine.name})";
              command = "latexmk-pdfname";
              args = [
                "-synctex=1"
                "-interaction=nonstopmode"
                "-file-line-error"
                engine.flag
                "-outdir=%OUTDIR%"
                "%DOC%"
              ];
            };

            recipeFor = engine: {
              inherit (engine) name;
              tools = [ "latexmk (${engine.name})" ];
            };
          in
          {
            vscodeProfiles.latex = {
              extensions = with pkgs.nix-vscode-extensions.open-vsx; [
                james-yu.latex-workshop
                streetsidesoftware.code-spell-checker
              ];

              userSettings = {
                "latex-workshop.latex.outDir" = "%DIR%";
                "latex-workshop.latex.recipe.default" = "lastUsed";
                "latex-workshop.latex.recipes" = map recipeFor engines;
                "latex-workshop.latex.tools" = map latexmkTool engines;
                "latex-workshop.latex.autoBuild.run" = "onFileChange";
                "latex-workshop.latex.autoBuild.interval" = 1000;
                "latex-workshop.latex.autoClean.run" = "onFailed";

                "latex-workshop.view.pdf.viewer" = "tab";
                "latex-workshop.view.pdf.tab.editorGroup" = "right";
                "latex-workshop.synctex.afterBuild.enabled" = true;
                "latex-workshop.view.pdf.internal.synctex.keybinding" = "double-click";

                "latex-workshop.formatting.latex" = "latexindent";
                "latex-workshop.intellisense.package.enabled" = true;
                "latex-workshop.bind.enter.key" = true;

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
                  "editor.formatOnSave" = true;
                  "editor.defaultFormatter" = "James-Yu.latex-workshop";
                  "editor.wordWrap" = "on";
                  "editor.wordWrapColumn" = 100;
                  "editor.autoClosingBrackets" = "always";
                  "editor.autoSurround" = "languageDefined";
                  "editor.suggest.snippetsPreventQuickSuggestions" = false;
                  "editor.quickSuggestions" = {
                    comments = false;
                    other = true;
                    strings = false;
                  };
                };

                "[bibtex]" = {
                  "editor.formatOnSave" = true;
                  "editor.defaultFormatter" = "James-Yu.latex-workshop";
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
