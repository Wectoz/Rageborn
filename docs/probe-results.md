# Probe results

The probe (`RagebornProbe`) tells us what the game lets an addon read during a fight.

## How to run it (about 5 minutes)

1. Log in on the warrior with the addon "Rageborn Probe (throwaway)" enabled.
2. Type `/rbprobe` while standing still, out of combat, with nothing targeted.
3. Target a mob your level and fight it. Stay in Battle Stance until it dodges once
   (Overpower lights up), then Defensive Stance with a shield until you block once.
4. Cast Battle Shout during the fight. Use Heroic Strike once.
5. Kill the mob.
6. Fight one mob that casts a spell, if one is nearby.
7. Type `/reload`. That writes the log to disk. Then tell Claude it is done.

The log is read from `WTF/Account/<account>/SavedVariables/RagebornProbe.lua`.

## Results

Filled in from the log. So far only the out-of-combat part has been run (log of 2026-11-20): the fight steps 3 to 6 are still open, so every "In combat" cell is empty. "plain" = readable, "secret" = hidden, "nil" = nothing returned.

| Check | Out of combat | In combat | Decision |
|---|---|---|---|
| UnitHealth player | | | |
| UnitHealthPercent player (ScaleTo100) | | | low-health version |
| UnitHealthPercent target (ScaleTo100) | | | |
| IsSpellUsable | | | must be plain |
| GetSpellCooldown startTime / duration | | | must be plain |
| IsCurrentSpell (Heroic Strike queued) | | | "queued" alert |
| Player aura Battle Shout expirationTime | | | |
| Target debuff spellId / applications / expirationTime | | | target alerts |
| UnitCastingInfo target | | | interrupt alert |
| UNIT_SPELLCAST_SUCCEEDED spell ID | plain | | must be plain |
| UNIT_COMBAT miss kind (player / target) | | | stance hint |
| PARTY_KILL | | | Victory Rush window |
| SPELL_ACTIVATION_OVERLAY_GLOW_SHOW | | | |
| Glow atlases present | both (proc loop, ants) | — | procLoop and ants glows stay |
| Overlay art files that load | 82 of 82 | — | whole game-art list stays |

## Spell ID and duration corrections

Checked on 2026-11-25 against the Forever client's own data tables (product `wowf`, build
1.60.1.71091, from wago.tools): spell names, stance requirements, durations, cooldowns, the
warrior talent tree and the sound kits. Every spell and sound the addon uses exists there,
except as corrected below.

| What | Was (Classic) | Forever |
|---|---|---|
| Human racial | 59752 (not in the client) | Will to Survive 1259718: removes stuns, 3 min |
| Orc racial (new) | none | Shatter Curse 1299026: removes curses |
| Bloodthrill buff | 1289682 (that is the talent) | buff 1289681 / 1282733, 5 s |
| Gore Drinker buff | 1323967 (the talent) | buff 1323969, 8 s: next melee attacks restore health |
| Enrage | five talent ranks, five buffs | one talent 12317, buff 12880, 12 s |
| Battle Shout | 120 s | 180 s |
| Shield Wall | 10 s | 12 s |
| Shield Block | 5 s | 7 s |
| Demoralizing Shout | hidden 30 s after a cast | 45 s (its duration) |
| Charge | Battle Stance only | also Defensive Stance with the talent Vanguard 1310317 |
| Reckless Swings (new) | none | talent 1329555, 8 s, 15 s cooldown |

Stances confirmed as the addon has them: Overpower Battle; Revenge, Taunt, Disarm, Shield
Block, Shield Wall Defensive; Pummel, Intercept, Whirlwind, Recklessness, Berserker Rage
Berserker; Execute and Hamstring Battle or Berserker; Rend, Thunder Clap, Shield Bash Battle or
Defensive; Mocking Blow, Retaliation, Sweeping Strikes Battle. Forever has one warrior talent
tree of 53 talents, not three tabs.

Still only checkable in game: whether the client lets an addon read these in combat.
