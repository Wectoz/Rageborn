#!/usr/bin/env bash
# Asks Codex (Astra 6.2, high effort) to review the MODERN painted proc art and propose
# improvements. It writes review.md here and changes no image.
cd "$(dirname "$0")"
cat > prompt.txt <<'PROMPT'
You are an art director reviewing game UI art. Do not generate or change any image in this task: look, judge, and write.

Context: "Rageborn" is a World of Warcraft Classic addon for the warrior class. When something important happens in a fight it shows glowing art AROUND the player's character: one piece left of the character and its mirror image on the right ("side"), or one piece arching above the head ("top"). The art is painted on pure black and drawn in game with additive blending, at roughly one eighth of the source size (a side piece is about 120x180 screen pixels, a top piece about 180x120). Nothing may cover the character.

The art to review is the MODERN set, in ../around/<alert>/ : for each of overpower, revenge, execute, victoryRush, interrupt, battleShout, lowHealth there are <alert>_side1.png, <alert>_side2.png (1024x1536) and <alert>_top1.png (1536x1024). ../around/sheet_all.png shows all of them on an in-game mock-up. Open and look at every one of the 21 images, and the sheet.

The owner's verdict on this set: "they look good, but really modern, and a little AI". The set is staying as the Modern option (a separate Legacy set exists), so the goal is not to make it old-fashioned: it is to make it better modern art and to remove what makes it look machine-made.

Write review.md in the current directory with:
1. Overall: the three to five things that most make this set read as AI-generated or generic, with the images that show each most clearly.
2. One short section per alert. For each of its three pieces: does it say what the alert means at a glance at in-game size? Does it obey the layout (side: the right 35% empty; top: the bottom-centre 35% empty; nothing cut off at the edges)? Its weaknesses. A verdict: KEEP, RETOUCH (say exactly what to change) or REPLACE (give the new motif in one sentence).
3. Set-level consistency: do the seven alerts look like one family, and are they different enough from each other to be told apart in a fight in under half a second? Name the pairs that are too alike.
4. A ranked list of the ten changes that would improve the set most, most valuable first.
5. For every piece marked REPLACE or RETOUCH: a ready-to-use image prompt that would produce the improved piece, following the same layout rules and the pure black background.

Be specific and critical; do not praise. Refer to images by file name. Reply with a five-line summary when review.md is written.
PROMPT
timeout 2400 codex exec --skip-git-repo-check -s workspace-write -m gpt-6.2-astra -c model_reasoning_effort='"high"' - < prompt.txt > codex.log 2>&1; echo "codex exit $?" >> codex.log
ls -la review.md 2>&1
