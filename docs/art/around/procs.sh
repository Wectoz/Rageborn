#!/usr/bin/env bash
cd "$(dirname "$0")"
RED="Blood-red and ember palette with a hot white core."
(
./run.sh revenge "REVENGE (the warrior just blocked, dodged or parried, and strikes back from behind the shield)" \
  "the curved rim of a great shield seen edge-on, glowing, with sparks flying off where a blow was blocked" \
  "a tall curved blade thrusting upward along a shield edge, both wreathed in fire" \
  "a wide shield crest arching overhead with two blades fanning out from behind it"
./run.sh execute "EXECUTE (the enemy is nearly dead: finish them with one killing blow)" \
  "a huge executioner axe blade, its crescent edge forming the curve, dripping embers" \
  "a tall jagged crescent of dark red fire like a reaper's scythe blade" \
  "a heavy axe head sweeping overhead leaving a blood-red arc of fire" "$RED"
) &
(
./run.sh victoryRush "VICTORY RUSH (the warrior just killed an enemy and surges forward, healing from the kill)" \
  "a rising wing made of golden and crimson flame feathers" \
  "a tall laurel branch made of fire, curving upward in triumph" \
  "a pair of flame wings spreading out from a bright central flare, arched like a crown" \
  "Gold and crimson palette with a hot white core."
./run.sh interrupt "INTERRUPT (the enemy is casting a spell: hit them now to stop it)" \
  "a curved arc of violet-blue magic runes being shattered by orange impact sparks" \
  "a tall crackling bolt of orange force curving like a bracket, breaking pale blue glyph fragments" \
  "a broken half-circle of arcane runes overhead, cracked through the middle by an orange strike" \
  "Warm gold and orange for the warrior's strike, with cold violet-blue for the broken magic."
) &
(
./run.sh battleShout "BATTLE SHOUT (a reminder that the warrior's war cry buff is missing: shout to empower the group)" \
  "three nested curved shockwave arcs of fiery sound, like a roar spreading outward" \
  "a tall curved war horn with sound-wave rings blasting from it" \
  "a wide plain war banner (no symbol on it) flaring overhead in fiery wind"
./run.sh lowHealth "LOW HEALTH WARNING (the warrior is about to die: press a defensive ability now)" \
  "a tall curved crack of pulsing red light, like a wound in the air, with drifting embers" \
  "a curved wall of red thorn-like blades and dripping blood drops" \
  "a jagged red crown of cracks arching overhead, pulsing like a heartbeat" "$RED"
) &
wait
echo "ALL DONE"
