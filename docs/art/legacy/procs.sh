#!/usr/bin/env bash
# The seven alerts with painted art, three at a time.
cd "$(dirname "$0")"
RED="Colour: one hue family only: blood red to dark orange, with a pale core."
(
./run.sh overpower "OVERPOWER (the enemy just dodged: the warrior may strike back at once with a blow that cannot be dodged)"
./run.sh revenge "REVENGE (the warrior just blocked, dodged or parried, and strikes back from behind the shield)"
./run.sh execute "EXECUTE (the enemy is nearly dead: finish them with one killing blow)" "$RED"
) &
(
./run.sh victoryRush "VICTORY RUSH (the warrior just killed an enemy and surges forward, healing from the kill)" "Colour: one hue family only: gold to yellow, with a pale core."
./run.sh interrupt "INTERRUPT (the enemy is casting a spell: hit them now with Pummel or Shield Bash to stop it)" "Colour: one hue family only: the cold blue-violet the old game used for arcane magic, with a pale core."
) &
(
./run.sh battleShout "BATTLE SHOUT (a reminder that the warrior's war cry buff is missing: shout to empower the group)"
./run.sh lowHealth "LOW HEALTH WARNING (the warrior is about to die: press a defensive ability now)" "$RED"
) &
wait
echo "ALL DONE"
# Added later (run these two by hand, as above):
#   ./run.sh goreDrinker "GORE DRINKER (after a rage ability such as Bloodthirst or Enrage, the Fury warrior's next melee attacks drink health back from the enemy)" "$RED"
#   ./run.sh enrage "ENRAGE (the warrior was struck hard and flies into a rage: for a few seconds he hits harder)" "$RED"
