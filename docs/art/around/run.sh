#!/usr/bin/env bash
# Painted overlay art that goes AROUND the character (never over it), made with Codex's
# image tool. Two side designs (drawn left of the character, mirrored on the right by the
# addon) and one top design (drawn above the character's head).
# usage: run.sh KEY "TITLE (what it means)" "side concept 1" "side concept 2" "top concept" ["palette note"]
set -u
cd "$(dirname "$0")"
key=$1; title=$2; s1=$3; s2=$4; t1=$5; palette=${6:-"Warm warrior palette (ember orange, gold, hot white core), with one accent colour allowed."}
mkdir -p "$key"
cat > "$key/prompt.txt" <<PROMPT
Use your image generation tool to create game UI art, then save the files in the current directory.

Context: "Rageborn" is an addon for a fantasy MMO, for the warrior class. When something important happens in a fight, the addon shows glowing art AROUND the player's character in the middle of the screen: one piece to the left of the character and its mirror image to the right, or one piece arching above the character's head. The art must never cover the character, so each piece hugs the outside like a bracket. This is the same idea as the game's own "spell activation overlay" effects. I need three pieces for one alert: $title

Rules for every image:
- Background pure flat black (#000000) with nothing in it: the art is drawn in game with additive blending, so black becomes transparent. No vignette, no smoke or haze filling the frame, no ground, no scenery.
- Hand-painted fantasy game-effect style: confident brush strokes, strong silhouette, glowing edges, trailing sparks and embers. $palette
- Readable when shrunk to one eighth of its size.
- No text, letters, numbers, borders, frames, UI chrome, logos, faction crests, characters or faces.
- Original designs only; do not copy any existing game's artwork.

SIDE pieces (two different designs). Tall portrait image, 1024 wide x 1536 high. This is the piece that stands to the LEFT of the character. The art must be a tall vertical shape curved like an opening parenthesis "(" : it bulges toward the LEFT edge of the image and its top and bottom ends curl toward the RIGHT. The art fills the full height. Keep the RIGHT 35% of the image completely black and empty: that is where the character stands.
1. ${key}_side1.png: $s1
2. ${key}_side2.png: $s2

TOP piece (one design). Wide landscape image, 1536 wide x 1024 high. This piece floats ABOVE the character's head. The art must be a wide shape arched like a rainbow or a crown: highest in the middle, both ends curving DOWN. The art fills the full width. Keep the BOTTOM-CENTRE 35% of the image completely black and empty: the character's head is there.
3. ${key}_top1.png: $t1

Save exactly these three PNG files in the current directory. Then reply with one line per file: the file name, its pixel size, and one sentence describing it. Do not create any other files.
PROMPT
( cd "$key" && timeout 1200 codex exec --skip-git-repo-check -s workspace-write - < prompt.txt > codex.log 2>&1; echo "codex exit $?" >> codex.log )
echo "$key: $(ls "$key"/*.png 2>/dev/null | wc -l) images"
