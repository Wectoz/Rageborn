#!/usr/bin/env bash
# Generates three painted art options for one alert with Codex's image tool.
# usage: run.sh KEY "TITLE (what it means)" "concept 1" "concept 2" "concept 3" ["palette note"]
set -u
cd "$(dirname "$0")"
key=$1; title=$2; c1=$3; c2=$4; c3=$5; palette=${6:-"Warm warrior palette (ember orange, gold, hot white core), with one accent colour allowed."}
mkdir -p "$key"
cat > "$key/prompt.txt" <<PROMPT
Use your image generation tool to create game UI art, then save the files in the current directory.

Context: "Rageborn" is an addon for a fantasy MMO, for the warrior class. When something important happens in a fight, the addon flashes a piece of art on screen near the character, like the game's own spell-alert overlays. I need three clearly different art options for one alert: $title

Requirements for every image:
- Square, 1024x1024.
- Background must be pure flat black (#000000) with nothing in it: the art is drawn in game with additive blending, so black becomes transparent. No vignette, no smoke filling the frame, no ground, no scenery.
- One bold emblem centred, filling about 70% of the frame, readable when shrunk to 128 pixels.
- Hand-painted fantasy game-icon style: confident brush strokes, strong silhouette, glowing edges. $palette
- No text, no letters, no numbers, no borders or frames, no UI chrome, no logos, no faction crests, no characters or faces.
- Original designs only; do not copy any existing game's artwork.

The three options must differ in concept, not just colour:
1. ${key}_1.png: $c1
2. ${key}_2.png: $c2
3. ${key}_3.png: $c3

Save exactly these three PNG files in the current directory. Then reply with one line per file: the file name, its pixel size, and one sentence describing it. Do not create any other files.
PROMPT
( cd "$key" && timeout 1200 codex exec --skip-git-repo-check -s workspace-write - < prompt.txt > codex.log 2>&1; echo "codex exit $?" >> codex.log )
echo "$key: $(ls "$key"/*.png 2>/dev/null | wc -l) images"
