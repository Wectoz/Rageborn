#!/usr/bin/env bash
cd "$(dirname "$0")"
RED="Blood-red and ember palette with a hot white core."
(
./run.sh revenge "REVENGE (the warrior just blocked, dodged or parried, and strikes back from behind the shield)" \
  "a shield with a blade thrusting out from behind it" \
  "a shield face cracking with fiery light as a counter-blow bursts through" \
  "two mirrored blade arcs sweeping outward from a central shield boss"
./run.sh execute "EXECUTE (the enemy is nearly dead: finish them with one killing blow)" \
  "a heavy executioner axe blade descending, trailing fire" \
  "a skull split by a glowing vertical blade cut (stylised, no face detail beyond a skull)" \
  "a broken hourglass or guttering flame cleaved by a sword stroke" "$RED"
) &
(
./run.sh victoryRush "VICTORY RUSH (the warrior just killed an enemy and surges forward, healing from the kill)" \
  "a blade raised upward wrapped in rising golden light and laurel-like flames" \
  "a winged sword shooting upward like a rising phoenix" \
  "a burst of red and gold energy rings exploding outward from a clenched gauntlet" \
  "Gold and crimson palette with a hot white core."
./run.sh interrupt "INTERRUPT (the enemy is casting a spell: hit them now to stop it)" \
  "a gauntleted fist smashing through a glowing magic rune circle, shattering it" \
  "a shield edge slamming into and breaking a spiral of arcane energy" \
  "a lightning-fast pommel strike cutting a spell glyph in half" \
  "Warm gold and orange for the warrior's strike, with cold violet-blue for the broken magic."
) &
(
./run.sh battleShout "BATTLE SHOUT (a reminder that the warrior's war cry buff is missing: shout to empower the group)" \
  "a war horn with powerful sound waves blasting out of it" \
  "a roaring lion-less abstract mouth of flame made of three expanding shockwave arcs" \
  "a battle standard (plain banner, no symbol) flaring in fiery wind with shockwave rings"
./run.sh lowHealth "LOW HEALTH WARNING (the warrior is about to die: press a defensive ability now)" \
  "a cracked heart made of molten metal, glowing red through the cracks" \
  "a shield with a red pulsing wound-like crack, braced and defiant" \
  "a dripping blood drop turning into a shield shape" "$RED"
) &
wait
echo "ALL DONE"
