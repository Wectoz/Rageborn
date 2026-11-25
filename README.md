# Rageborn

A warrior-only addon for WoW Forever (Interface 16001) and Classic Era, including Hardcore and Season of Discovery, which use the Era client (Interface 11508/11509). It shows procs, reminders and active cooldowns as on-screen alerts, makes the matching action buttons glow (macro buttons included), and offers a page of ready-made warrior macros.

On any other class it loads nothing.

## What it does

- **Alerts** for Overpower, Revenge, Execute, Victory Rush, interrupts, Battle Shout, queued swings, defensive and offensive cooldowns, low health, and four debuffs on the target. Each has its own design, colour, size, opacity, sound and place on screen.
- **Designs**: painted art, drawn shapes (ring, side arcs, pulsing frame, bar, screen edges) and the game's own proc art, browsed in the Gallery.
- **Button glow** in four kinds (proc loop, marching ants, pulsing border, rotating corners), also on macros that cast the spell.
- **Macros**: seven ready-made macros (stance swaps, shield swaps, mouseover Taunt) created as character macros named `RB <name>`.
- **Profiles**: per character by default; create, copy, rename, delete. Start one from a preset (Arms, Fury, Protection, or Empty with every alert off), share one as text, and switch by talent tree.
- **Consumables**: warrior flasks, elixirs, food, weapon stones, potions and enchants, best first, for damage and for tanking, with who makes each, at what skill, from which materials, and how many you carry. Shift-click a material to search for it at the auction house. The list is the right one for the client: Forever's reworked items, or Classic's.
- **Minimap button**: left click opens the settings, right click toggles test mode.
- **Sounds** are off until you turn them on.

## Commands

| Command | Does |
|---|---|
| `/rb` or `/rageborn` | Opens the settings window (also in the addon compartment and Options > AddOns) |
| `/rb test` | Shows every enabled alert; again hides them |
| `/rb move` | Drag the alerts into place; again locks them |
| `/rb reset` | Resets the current profile |
| `/rb sounds` | All sounds on or off |
| `/rb crit <sound>` | Sets the critical-hit sound; without a sound, lists them |

## Action bars

Buttons are found on the default bars, EllesmereUI, Dominos, Bartender4 and ElvUI. Only EllesmereUI and the default bars are installed on the machine it was built on; the other three are written from their button names and are untested.

## Clients

| Client | Loads | Differences |
|---|---|---|
| Forever | `Rageborn_Camelot.toc` (or `Rageborn.toc`) | Everything, including Forever talents: Gore Drinker, Bloodthrill, Reckless Swings, Vanguard |
| Classic Era, Hardcore, SoD | `Rageborn_Vanilla.toc` | Classic durations (Battle Shout 120 s, Shield Wall 10 s, Shield Block 5 s). Alerts for spells the character doesn't have are simply absent. No stun-break racial for humans. No addon-compartment button; the minimap button and `/rb` open the settings. |

Not supported: Anniversary (TBC), Mists Classic, Retail.

## Known limits

- Timers of pressed cooldowns are estimates from the spell's known duration, not read from the buff.
- Spell IDs, durations and stances are checked against the Forever client's data tables (build 1.60.1); how they behave in a fight is not yet confirmed in game (`docs/ingame-checklist.md`).
- In combat the client hides some values from addons. What it hides is not fully measured yet (`docs/probe-results.md`); an alert that can't be read keeps its last state instead of erroring. Target-debuff alerts depend on this and are off by default.
- The critical-hit sound plays for any crit on your target, including other players': the game doesn't say who dealt it.
- Buttons are re-read after combat, not during it: a bar page that changes in a fight (stance bars) may glow late.
- Macros and profiles can't be created or switched in combat.
- The Demoralizing Shout pull alert counts enemies by their nameplates: enemy nameplates must be on, and it counts every enemy in combat on screen, whoever it is fighting.
- The racial glow lights the race's escape when it would help: human when stunned, gnome when rooted or slowed, undead when feared or charmed, dwarf when poisoned or diseased. Orc, troll, tauren and night elf racials are not covered.

## Development

```
lua5.1 tests/run.lua    # must print ALL PASS
./deploy.sh             # copies the addon into the game's AddOns folder
```

Design and plan: `docs/superpowers/`. In-game sign-off: `docs/ingame-checklist.md`.
