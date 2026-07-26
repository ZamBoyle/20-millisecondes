#!/bin/bash
# Genere le PDF de l'edition publique du livre (pandoc + XeLaTeX).
# Usage : ./tools/livre/build_pdf.sh  -> docs/AU-COEUR-DU-METAL-C64-U64.pdf
set -e
cd "$(dirname "$0")/../.."
SRC=docs/AU-COEUR-DU-METAL-C64-U64.md
TMP=$(mktemp -d)
python3 - "$SRC" "$TMP/pre.md" <<'PY'
import re, sys
s=open(sys.argv[1]).read()
s=s.replace('️','')                              # variation selector (emoji)
s=re.sub(r'^# AU CŒUR DU MÉTAL\n### [^\n]+\n','',s)   # titre -> page de titre LaTeX
s=re.sub(r'## Table des matières\n.*?\n---\n','',s,flags=re.S)  # TdM -> TdM LaTeX
s='# Avant-propos\n\n'+s
open(sys.argv[2],'w').write(s)
PY
pandoc "$TMP/pre.md" -f gfm -o docs/AU-COEUR-DU-METAL-C64-U64.pdf --pdf-engine=xelatex \
  -H tools/livre/header.tex -B tools/livre/titlepage.tex --toc --toc-depth=2 \
  --lua-filter=tools/livre/widths.lua --resource-path=.:tools/livre/figs \
  -V documentclass=report -V fontsize=10pt -V lang=fr \
  -V colorlinks -V linkcolor=linkc -V urlcolor=linkc --top-level-division=chapter
rm -rf "$TMP"
echo "OK -> docs/AU-COEUR-DU-METAL-C64-U64.pdf"
