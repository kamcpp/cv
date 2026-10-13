#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

HTML_FILE="afsaneh-sadeghnia-cv.html"
PHOTO_HTML_FILE="afsaneh-sadeghnia-cv-photo.html"
PHOTO_FILE="afsaneh-sadeghnia.png"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

if [ ! -x "$CHROME" ]; then
  echo "Google Chrome not found at: $CHROME" >&2
  exit 1
fi

# The photo variant is generated from the plain CV so the two never drift:
# the photo is resized, converted to JPEG and embedded as a data URI.
PHOTO_TMP="$(mktemp -t afsaneh-photo).jpg"
sips -s format jpeg -s formatOptions 85 -Z 600 "$PHOTO_FILE" --out "$PHOTO_TMP" >/dev/null
python3 -I - "$HTML_FILE" "$PHOTO_HTML_FILE" "$PHOTO_TMP" <<'PY'
import base64, sys
src, dst, photo = sys.argv[1:4]
s = open(src).read()
b64 = base64.b64encode(open(photo, 'rb').read()).decode()
css = """  .top-section {
    gap: 0;
  }

  .contact-block {
    margin-top: 40pt;
  }

  .photo {
    flex: 0 0 auto;
    width: 2.4cm;
    height: 3cm;
    object-fit: cover;
    margin-left: 0.3cm;
    margin-top: 17pt;
    align-self: flex-start;
  }

"""
img = f'\n    <img class="photo" src="data:image/jpeg;base64,{b64}" alt="Afsaneh Sadeghnia">\n'
anchor = '  .top-section .name-block {'
assert s.count(anchor) == 1
s = s.replace(anchor, css + anchor)
end = '    </div>\n  </div>\n\n  <h2'
assert s.count(end) == 1
s = s.replace(end, '    </div>' + img + '  </div>\n\n  <h2')
s = s.replace('<title>Afsaneh Sadeghnia - CV</title>', '<title>Afsaneh Sadeghnia - CV (with photo)</title>')
open(dst, 'w').write(s)
PY
rm -f "$PHOTO_TMP"

PDF_FILES=()
for F in "$HTML_FILE" "$PHOTO_HTML_FILE"; do
  PDF_FILE="${F%.html}.pdf"
  "$CHROME" \
    --headless \
    --disable-gpu \
    --no-pdf-header-footer \
    --print-to-pdf="$PDF_FILE" \
    --print-to-pdf-no-header \
    "file://$(pwd)/$F" 2>/dev/null
  echo "Wrote $PDF_FILE"
  xattr -d com.apple.quarantine "$PDF_FILE" 2>/dev/null || true
  open -a Preview "$PDF_FILE"
  PDF_FILES+=("$PDF_FILE")
done

# Preview re-adds the quarantine flag whenever it (re)loads the file, which can
# happen well after this script exits, so keep clearing it in the background
# for a few minutes. A newer run replaces the watcher of an older one.
WATCHER_PID_FILE="${TMPDIR:-/tmp}/afsaneh-sadeghnia-cv-quarantine.pid"
if [ -f "$WATCHER_PID_FILE" ]; then
  kill "$(cat "$WATCHER_PID_FILE")" 2>/dev/null || true
fi
(
  for _ in $(seq 1 300); do
    sleep 1
    for PDF_FILE in "${PDF_FILES[@]}"; do
      xattr -d com.apple.quarantine "$PDF_FILE" 2>/dev/null || true
    done
  done
) >/dev/null 2>&1 &
echo $! > "$WATCHER_PID_FILE"
