# Rageborn

A warrior addon for WoW Forever and Classic Era. It tells you when to press things.

When Overpower lights up, or Revenge, or your target drops into Execute range, art appears around your character and the button on your bar starts glowing. Same for Battle Shout running out, a cooldown ticking down, or your health getting low enough that you should probably hit Shield Wall.

It only loads on warriors. On any other class it does nothing at all.

This is an early version and it hasn't seen much play yet. Things will be off. If something breaks or looks wrong, open an issue and tell me what you were doing.

## Installing

1. Click the green **Code** button on this page and pick **Download ZIP**.
2. Unzip it. Inside is a folder called `Rageborn`. That folder is the addon; the rest is art sources and tests you don't need.
3. Copy `Rageborn` into your AddOns folder:
   - Forever: `World of Warcraft\_forever_\Interface\AddOns`
   - Classic Era, Hardcore, Season of Discovery: `World of Warcraft\_classic_era_\Interface\AddOns`
4. Start the game, or type `/reload` if it's already running.

Type `/rb` to open the settings. There's also a minimap button.

## What you get

**Alerts.** Overpower, Revenge, Execute, Victory Rush, an interrupt reminder when your target is casting, Battle Shout, Enrage, your big cooldowns while they're running, low health, and a few for tanks: Sunder Armor stacks, a nudge when Rend or Thunder Clap has fallen off, Demoralizing Shout when you pull a pack, and Taunt when a mob runs off to someone else. On Forever it also knows Gore Drinker, Bloodthrill and Reckless Swings.

You only see alerts for abilities your character actually has. No Victory Rush on Era, no Forever talents either.

**Looks.** Every alert can have its own design, colour, size and place on screen. There are two sets of painted art to pick from: Modern, which is clean and bright, and Legacy, which is meant to look like it shipped with the old game. If you'd rather keep it plain there are rings, bars and frames, and the game's own proc art is in there too.

**Button glow.** The matching button on your bars glows while an alert is up. It works on macros as well, as long as the macro casts the spell. Four glow styles, any colour.

**Sounds.** Off by default. If you want them, each alert can play one, and there's a separate sound for crits. The list has around a hundred to choose from, including spell sounds from every class.

**Macros.** A page of ready-made warrior macros: stance swaps for Overpower, Pummel, Execute and the rest, shield swaps for Shield Bash and Shield Wall, mouseover Taunt and Charge. Click Create and it's added to your character's macros. It never overwrites one you already have.

**Consumables.** Flasks, elixirs, food, sharpening stones, potions and enchants for damage and for tanking, best first. Each one shows who makes it, at what skill, and what it takes to craft. Shift-click a material with the auction house open and it's typed into the search box for you. Forever and Era get different lists, because Forever changed a lot of these items.

**Profiles.** Start from Arms, Fury or Protection and change what you like, or start empty and turn on only what you want. You can have the addon switch profile when you respec, and you can copy a profile out as text to share with someone.

## Commands

| Type this | To |
|---|---|
| `/rb` | Open or close the settings |
| `/rb test` | Show all your alerts so you can see how they look |
| `/rb move` | Drag alerts where you want them. Type it again to lock them |
| `/rb reset` | Put the current profile back to its defaults |
| `/rb sounds` | Turn all sounds on or off |

## Which versions of the game

| Game | Works? |
|---|---|
| WoW Forever | Yes |
| Classic Era, Hardcore, Season of Discovery | Yes |
| Anniversary (TBC), Mists Classic, Retail | No |

## Action bar addons

The glow finds buttons on the default bars, EllesmereUI, Dominos, Bartender4 and ElvUI. I only use EllesmereUI and the default bars myself, so the other three are untested. If the glow doesn't show up on yours, let me know which one you run.

## Good to know

- Cooldown timers count down from when you press the button. They aren't read from the buff, so a cooldown that ends early will still show until its time is up.
- The crit sound plays on any crit against your target, including other people's. The game doesn't tell addons who landed it.
- If you swap stance in the middle of a fight and your bar changes with it, the glow may not find the new buttons until combat ends.
- Demoralizing Shout on a pull counts enemies by their nameplates, so enemy nameplates need to be on.
- The game hides some information from addons during combat. An alert that can't be read right then stays as it was until it can.
- You can't create macros or switch profiles in combat. That's the game's rule, not mine.
- On Forever, nobody seems to have tested yet whether two elixirs that give the same stat both count. The Consumables page says so where it matters.

## For anyone poking at the code

Plain Lua, no libraries. Tests run outside the game:

```
lua5.1 tests/run.lua
```

`docs/ingame-checklist.md` is the list of things that still need checking in a real client.
