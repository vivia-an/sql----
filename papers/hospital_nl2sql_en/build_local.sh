#!/usr/bin/env bash
# Build main_applsci_mdpicls.tex on this machine.
#
# The manuscript itself is clean: it is the MDPI template file, and on Overleaf
# or any current TeX Live it compiles as-is with `pdflatex` twice. Two things
# are wrong with THIS machine, and both are patched here rather than in the
# manuscript, so that nothing local ever travels with the submission:
#
#   1. No ghostscript. mdpi.cls asks for Definitions/*.eps and pdftex cannot
#      read EPS without gs. The build directory therefore gets its own
#      Definitions/ where every .eps the class names is a PDF stand-in, plus a
#      graphics rule telling pdftex to read them as PDF. The repository's real
#      Definitions/ is left untouched.
#   2. TeX Live 2013's caption3 defines \l@addto@macro; KOMA's scrbase, loaded
#      later by the class, redefines it with \newcommand and errors out. The
#      shim undefines it in between.
#
# Usage:  ./build_local.sh [outdir]
# Result: $outdir/main_applsci_mdpicls.pdf, plus an error/page/overfull summary.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
# Default to a build directory outside the repository. The session scratchpad is
# preferred when one exists; the name changes per session, so pick the newest
# rather than hard-coding one that will be retired.
DEFAULT_OUT="$(ls -dt /tmp/claude-*/-root-sqlge/*/scratchpad 2>/dev/null | head -1)"
OUT="${1:-${DEFAULT_OUT:-/tmp/applsci-build}}"
JOB=main_applsci_mdpicls

mkdir -p "$OUT/Definitions"
for f in "$HERE"/Definitions/*; do ln -sf "$f" "$OUT/Definitions/"; done

if ! command -v gs >/dev/null 2>&1; then
  STAND_IN="$HERE/figs/.eps-stand-in.pdf"
  [ -f "$STAND_IN" ] || STAND_IN=/root/texmf/tex/latex/mdpi/logo-mdpi.pdf
  for n in logo-mdpi logo-updates applsci-logo logo-ccby logo-ccby-nc-nd \
           logo-conference logo-mdpi-scipharm logo-mdpi-ijom logo-mdpi-siuj; do
    rm -f "$OUT/Definitions/$n.eps"
    cp -f "$STAND_IN" "$OUT/Definitions/$n.eps" 2>/dev/null
  done
fi

{
  cat <<'SHIM'
%--- LOCAL BUILD SHIM - prepended by build_local.sh, not part of the submission
\RequirePackage{scrlfile}
\makeatletter
\BeforePackage{scrbase}{\let\l@addto@macro\@undefined}
\makeatother
\AtBeginDocument{\DeclareGraphicsRule{.eps}{pdf}{.eps}{}}
%-----------------------------------------------------------------------------
SHIM
  cat "$HERE/$JOB.tex"
} > "$OUT/$JOB.tex"

cd "$OUT" || exit 1
rm -f "$JOB.aux" "$JOB.pdf"
for _ in 1 2; do
  pdflatex -interaction=nonstopmode "$JOB.tex" >/dev/null 2>&1
done

errs=$(grep -c '^! ' "$JOB.log")
over=$(grep -c 'Overfull .hbox' "$JOB.log")
pages=$(pdfinfo "$JOB.pdf" 2>/dev/null | awk '/^Pages/{print $2}')
echo "$JOB: errors=$errs overfull=$over pages=${pages:-none}"
if [ "$errs" != "0" ]; then
  grep -A3 '^! ' "$JOB.log" | head -20
  exit 1
fi
