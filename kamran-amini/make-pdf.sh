#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

HTML_FILE="kamran-amini-cv.html"
PDF_FILE="kamran-amini-cv.pdf"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

if [ ! -x "$CHROME" ]; then
  echo "Google Chrome not found at: $CHROME" >&2
  exit 1
fi

"$CHROME" \
  --headless \
  --disable-gpu \
  --no-pdf-header-footer \
  --print-to-pdf="$PDF_FILE" \
  --print-to-pdf-no-header \
  "file://$(pwd)/$HTML_FILE"

echo "Wrote $PDF_FILE"

xattr -d com.apple.quarantine "$PDF_FILE" 2>/dev/null || true

open "$PDF_FILE"
