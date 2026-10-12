#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

if [ ! -x "$CHROME" ]; then
  echo "Google Chrome not found at: $CHROME" >&2
  exit 1
fi

# Build every cover letter, or only the ones given as arguments.
if [ $# -gt 0 ]; then
  HTML_FILES=("$@")
else
  HTML_FILES=(*.html)
fi

for HTML_FILE in "${HTML_FILES[@]}"; do
  PDF_FILE="${HTML_FILE%.html}.pdf"
  "$CHROME" \
    --headless \
    --disable-gpu \
    --no-pdf-header-footer \
    --print-to-pdf="$PDF_FILE" \
    --print-to-pdf-no-header \
    "file://$(pwd)/$HTML_FILE" 2>/dev/null
  echo "Wrote $PDF_FILE"
  xattr -d com.apple.quarantine "$PDF_FILE" 2>/dev/null || true
  open -a Preview "$PDF_FILE"
done
