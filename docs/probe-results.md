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

Filled in from the log. "plain" = readable, "secret" = hidden, "nil" = nothing returned.

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
| UNIT_SPELLCAST_SUCCEEDED spell ID | | | must be plain |
| UNIT_COMBAT miss kind (player / target) | | | stance hint |
| PARTY_KILL | | | Victory Rush window |
| SPELL_ACTIVATION_OVERLAY_GLOW_SHOW | | | |
| Glow atlases present | | — | |
| Overlay art files that load | | — | |

## Spell ID and duration corrections

None yet.
