#!/usr/bin/env bash
# Builds Rageborn/Media/icon.tga from the bottom-left quarter of docs/icons/gpt/source.png.
set -e
cd "$(dirname "$0")/.."
TMP=$(mktemp -d)
cat > "$TMP/icon.html" <<HTML
<body style="margin:0;width:64px;height:64px;background:url(file://$PWD/docs/icons/gpt/source.png) 0 100%/129px 129px"></body>
HTML
google-chrome --headless=new --no-sandbox --disable-gpu --hide-scrollbars --allow-file-access-from-files \
  --window-size=64,64 --screenshot="$TMP/icon.png" "file://$TMP/icon.html" >/dev/null 2>&1
python3 -I tools/png2tga.py "$TMP/icon.png" Rageborn/Media/icon.tga
rm -rf "$TMP"
# The blade's inlay is painted green; the owner wants it red: turn green hues to red in place.
python3 -I - Rageborn/Media/icon.tga <<'PY'
import sys, colorsys
p = sys.argv[1]; b = bytearray(open(p, "rb").read())
for i in range(18, len(b) - 3, 4):
    h, s, v = colorsys.rgb_to_hsv(b[i + 2] / 255, b[i + 1] / 255, b[i] / 255)
    if 0.17 < h < 0.50 and s > 0.15:                       # yellow-green to cyan-green
        r, g, bl = colorsys.hsv_to_rgb(0.99, min(1, s * 1.15), v)
        b[i], b[i + 1], b[i + 2] = int(bl * 255), int(g * 255), int(r * 255)
open(p, "wb").write(b)
PY
