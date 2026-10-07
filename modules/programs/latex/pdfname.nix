# modules/programs/latex/pdfname.nix
################################################################################
# Wraps latexmk as `latexmk-pdfname`, which builds exactly as latexmk does and
# then, only when a document asks for it, writes a second copy of the PDF under
# a name the document chooses.
#
# A document opts in with a magic comment, or a project opts in with a
# `.texpdfname` file in the document directory or any parent:
#
#     % !TeX pdfname = auto                      -> Resume-20260922.pdf
#     % !TeX pdfname = Family-Budget-{date}
#     % !TeX pdfname = {name}-{date:%Y-%m-%d}
#     % !TeX pdfname.replace = true              -> drop the previous date
#
# {name} is the .tex name with a trailing -YYYYMMDD removed, {date} is today,
# and {date:FORMAT} takes any strftime format. Documents that say nothing get
# plain latexmk behaviour.
#
# latexmk can already rename its own output through $jobname, but LaTeX Workshop
# finds the PDF to display by the name of the root .tex file, so renaming in
# latexmk costs the preview tab and SyncTeX. Copying afterwards keeps both.
################################################################################
{ ... }:
{
  flake.aspects =
    { aspects, ... }:
    {
      programs.latex.pdfname = {
        includes = with aspects; [ programs.latex.texlive ];

        homeManager =
          { pkgs, ... }:
          {
            home.packages = [
              (pkgs.writeShellApplication {
                name = "latexmk-pdfname";
                runtimeInputs = with pkgs; [
                  coreutils
                  findutils
                ];
                text = ''
                  latexmk "$@"

                  readonly defaultDateFormat="%Y%m%d"
                  readonly projectTemplateFile=".texpdfname"

                  trimWhitespace() {
                    local text="$1"
                    if [[ "$text" =~ ^[[:space:]]*(.*[^[:space:]])[[:space:]]*$ ]]; then
                      text="''${BASH_REMATCH[1]}"
                    fi
                    printf '%s' "$text"
                  }

                  templateFromDocument() {
                    local documentPath="$1" line
                    shopt -s nocasematch
                    while IFS= read -r line; do
                      if [[ "$line" =~ ^[[:space:]]*%+[[:space:]]*!?tex[[:space:]]+pdfname[[:space:]]*=[[:space:]]*(.+)$ ]]; then
                        trimWhitespace "''${BASH_REMATCH[1]}"
                        break
                      fi
                    done <"$documentPath"
                    shopt -u nocasematch
                  }

                  templateFromProject() {
                    local searchDirectory="$1" line
                    while :; do
                      if [[ -f "$searchDirectory/$projectTemplateFile" ]]; then
                        while IFS= read -r line; do
                          if [[ ! "$line" =~ ^[[:space:]]*(#|$) ]]; then
                            trimWhitespace "$line"
                            break
                          fi
                        done <"$searchDirectory/$projectTemplateFile"
                        return
                      fi
                      if [[ "$searchDirectory" == "/" ]]; then
                        return
                      fi
                      searchDirectory="$(dirname "$searchDirectory")"
                    done
                  }

                  replaceRequested() {
                    local documentPath="$1" line
                    shopt -s nocasematch
                    while IFS= read -r line; do
                      if [[ "$line" =~ ^[[:space:]]*%+[[:space:]]*!?tex[[:space:]]+pdfname\.replace[[:space:]]*=[[:space:]]*(true|yes|1)[[:space:]]*$ ]]; then
                        shopt -u nocasematch
                        return 0
                      fi
                    done <"$documentPath"
                    shopt -u nocasematch
                    return 1
                  }

                  # A same-shape glob: every digit the date produced becomes [0-9], so pruning an
                  # earlier build can never match a hand-named PDF such as Resume-FINAL.pdf.
                  digitGlob() {
                    local text="$1" index character result=""
                    for ((index = 0; index < ''${#text}; index++)); do
                      character="''${text:index:1}"
                      if [[ "$character" == [0-9] ]]; then
                        result+="[0-9]"
                      else
                        result+="$character"
                      fi
                    done
                    printf '%s' "$result"
                  }

                  renderTemplate() {
                    local text="$1" documentName="$2" asGlob="$3" format rendered
                    text="''${text//\{name\}/$documentName}"
                    while [[ "$text" =~ \{date:([^}]*)\} ]]; do
                      format="''${BASH_REMATCH[1]}"
                      rendered="$(date +"$format")"
                      if [[ "$asGlob" == "glob" ]]; then
                        rendered="$(digitGlob "$rendered")"
                      fi
                      text="''${text/\{date:$format\}/$rendered}"
                    done
                    if [[ "$text" == *"{date}"* ]]; then
                      rendered="$(date +"$defaultDateFormat")"
                      if [[ "$asGlob" == "glob" ]]; then
                        rendered="$(digitGlob "$rendered")"
                      fi
                      text="''${text//\{date\}/$rendered}"
                    fi
                    printf '%s' "''${text//\//-}"
                  }

                  document=""
                  outputDirectory=""
                  for argument in "$@"; do
                    case "$argument" in
                    -outdir=*) outputDirectory="''${argument#-outdir=}" ;;
                    -output-directory=*) outputDirectory="''${argument#-output-directory=}" ;;
                    -*) ;;
                    *) document="$argument" ;;
                    esac
                  done

                  if [[ -z "$document" ]]; then
                    exit 0
                  fi
                  if [[ "$document" != *.tex ]]; then
                    document="$document.tex"
                  fi
                  if [[ ! -f "$document" ]]; then
                    exit 0
                  fi

                  documentDirectory="$(cd "$(dirname "$document")" && pwd)"
                  documentFile="$(basename "$document")"
                  documentStem="''${documentFile%.tex}"

                  if [[ -z "$outputDirectory" ]]; then
                    outputDirectory="$documentDirectory"
                  elif [[ "$outputDirectory" != /* ]]; then
                    outputDirectory="$documentDirectory/$outputDirectory"
                  fi

                  template="$(templateFromDocument "$documentDirectory/$documentFile")"
                  if [[ -z "$template" ]]; then
                    template="$(templateFromProject "$documentDirectory")"
                  fi
                  if [[ -z "$template" ]]; then
                    exit 0
                  fi

                  shopt -s nocasematch
                  if [[ "$template" == "auto" ]]; then
                    template="{name}-{date}"
                  fi
                  shopt -u nocasematch

                  documentName="$documentStem"
                  if [[ "$documentName" =~ ^(.+)-[0-9]{8}$ ]]; then
                    documentName="''${BASH_REMATCH[1]}"
                  fi

                  builtPdf="$outputDirectory/$documentStem.pdf"
                  if [[ ! -f "$builtPdf" ]]; then
                    echo "latexmk-pdfname: latexmk produced no $builtPdf, leaving names alone" >&2
                    exit 0
                  fi

                  targetName="$(renderTemplate "$template" "$documentName" "value")"
                  targetPdf="$documentDirectory/$targetName.pdf"

                  if [[ "$builtPdf" -ef "$targetPdf" ]]; then
                    echo "==> $targetPdf"
                    exit 0
                  fi

                  cp -p "$builtPdf" "$targetPdf"
                  echo "==> $targetPdf"

                  if replaceRequested "$documentDirectory/$documentFile"; then
                    targetGlob="$(renderTemplate "$template" "$documentName" "glob")"
                    if [[ "$targetGlob" != "$targetName" ]]; then
                      while IFS= read -r stalePdf; do
                        if [[ -f "$stalePdf" && ! "$stalePdf" -ef "$targetPdf" && ! "$stalePdf" -ef "$builtPdf" ]]; then
                          rm -f "$stalePdf"
                          echo "    removed stale $(basename "$stalePdf")"
                        fi
                      done < <(find "$documentDirectory" -maxdepth 1 -type f -name "$targetGlob.pdf")
                    fi
                  fi
                '';
              })
            ];
          };
      };
    };
}
