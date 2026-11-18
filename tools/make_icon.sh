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
