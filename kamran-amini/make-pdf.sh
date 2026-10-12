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

# Preview re-adds the quarantine flag whenever it (re)loads the file, which can
# happen well after this script exits, so keep clearing it in the background
# for a few minutes. A newer run replaces the watcher of an older one.
WATCHER_PID_FILE="${TMPDIR:-/tmp}/kamran-amini-cv-quarantine.pid"
if [ -f "$WATCHER_PID_FILE" ]; then
  kill "$(cat "$WATCHER_PID_FILE")" 2>/dev/null || true
fi
(
  for _ in $(seq 1 300); do
    sleep 1
    xattr -d com.apple.quarantine "$PDF_FILE" 2>/dev/null || true
  done
) >/dev/null 2>&1 &
echo $! > "$WATCHER_PID_FILE"
