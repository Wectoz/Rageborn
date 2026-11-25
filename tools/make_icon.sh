#!/usr/bin/env bash
# Builds Rageborn/Media/icon.tga (64x64) from the bottom-left quarter of
# docs/icons/gpt/source.png. The blade's inlay is painted green there and the owner wants it
# red, so the green hues are turned red at the source's full size, before scaling down:
# that keeps the edges smooth. Also writes a 256 px preview, docs/icons/icon_red_preview.png.
set -e
cd "$(dirname "$0")/.."
TMP=$(mktemp -d)
python3 -I - docs/icons/gpt/source.png "$TMP/red.png" <<'PY'
import sys, colorsys, struct, zlib
sys.path.insert(0, "tools")
from png2tga import read_png
w, h, bpp, rows = read_png(sys.argv[1])
x0, y0 = 0, h // 2                                   # bottom-left quarter
out = []
for y in range(y0, h):
    line, row = rows[y], bytearray()
    for x in range(x0, w // 2):
        r, g, b = line[x * bpp], line[x * bpp + 1], line[x * bpp + 2]
        hue, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        if 0.17 < hue < 0.50:                         # yellow-green to cyan-green
            k = min(1.0, s / 0.25)                    # faint greens change only a little
            nr, ng, nb = colorsys.hsv_to_rgb(0.99, min(1, s * 1.15), v)
            r, g, b = (int(r + (nr * 255 - r) * k), int(g + (ng * 255 - g) * k), int(b + (nb * 255 - b) * k))
        row += bytes((r, g, b))
    out.append(b"\0" + bytes(row))
def chunk(k, d): return struct.pack(">I", len(d)) + k + d + struct.pack(">I", zlib.crc32(k + d))
open(sys.argv[2], "wb").write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w // 2, h - y0, 8, 2, 0, 0, 0))
                              + chunk(b"IDAT", zlib.compress(b"".join(out))) + chunk(b"IEND", b""))
PY
shot() { # size out.png
  cat > "$TMP/icon.html" <<HTML
<body style="margin:0;width:$1px;height:$1px;background:url(file://$TMP/red.png) 0 0/$1px $1px"></body>
HTML
  google-chrome --headless=new --no-sandbox --disable-gpu --hide-scrollbars --allow-file-access-from-files \
    --window-size=$1,$1 --screenshot="$2" "file://$TMP/icon.html" >/dev/null 2>&1
}
shot 64 "$TMP/icon.png"
python3 -I tools/png2tga.py "$TMP/icon.png" Rageborn/Media/icon.tga
shot 256 docs/icons/icon_red_preview.png
rm -rf "$TMP"
