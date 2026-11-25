# In-game test session

One route through everything, about 45 minutes. Nothing here has been seen in the client yet.
Tick a line when it works; write what you saw next to one that doesn't. Parts 1 and 2 need no
fighting; do them first, because an error at load makes the rest pointless.

## Before you start

- [ ] Run `./deploy.sh`, log in on the warrior, enable **Rageborn** and **Rageborn Probe (throwaway)**.
- [ ] Type `/console scriptErrors 1` so Lua errors pop up. Keep BugSack on.
- [ ] Turn enemy nameplates on (the multi-pull alerts count them).

**If an error pops up at any point:** copy its first three lines and note what you had just done. That is worth more than the rest of the list.

## Part 1: it loads (2 minutes)

- [ ] No Lua error at login.
- [ ] `/rb` opens the settings window; `/rb` again closes it.
- [ ] `/rb test` shows every enabled alert with a running timer; again hides them.
- [ ] The minimap button is there, with the ring centred on the icon. Left click opens the settings, right click toggles test mode, the tooltip shows.
- [ ] Options > AddOns lists Rageborn with a button that opens the window.

## Part 2: the settings window, standing still (15 minutes)

### Look and General

- [ ] The window is oxblood and bone: red title bar (darker at the foot), solid red selected row, red ticks; no orange anywhere.
- [ ] It drags by the title bar, closes on Escape, and reopens where you left it after `/reload`.
- [ ] General, bottom row: **Window** 70–130 % resizes it and it stays in place. The three lists open upwards.
- [ ] **Headings** and **Text**: try Friz Quadrata, Morpheus, Skurri, Arial Narrow on each. Note which you like, and any page where text is cut off or overlaps.
- [ ] Enable, size of all alerts, glow for every macro spell, Move, Test all, the minimap button tick box, Reset everything (asks first).
- [ ] Drag the minimap button around the minimap; `/reload` keeps its place.

### An alert page (use Overpower)

- [ ] Each alert in the left list has its spell or talent icon (your racial's own icon, a skull for Low health); no question marks, and no name runs into the edge.
- [ ] The left list shows only alerts the warrior knows, grouped. Every page has one line under its name starting "Press now", "Active effect", "Reminder", "On the target" or "Warning".
- [ ] With `/rb test` on, change every control: enabled, show on screen, colour, tint, size, opacity, spread, side, icon, name, timer, sound + Play, combat only, stance hint, glow, glow kind, glow colour. The preview follows, and so does the real alert.
- [ ] **Colour** opens the game's colour wheel; picking recolours the art live and ticks Tint; Cancel puts it back; unticking Tint returns the art's own colours.
- [ ] The design's menu shows after its name, e.g. "Overpower: sides 1 (Legacy)".
- [ ] Threshold sliders exist on Battle Shout, Low health, Demo Shout: pull, Sunder and Rage dump, and nowhere else.
- [ ] Racial ability (under Defensives): "Show on screen" is off and the appearance controls are greyed.
- [ ] Gore Drinker and Enrage are under Procs (only with the talent) and their pages have no Button glow section.

### Gallery

- [ ] Browse designs opens the Gallery for that alert; **Modern** and **Legacy** switch the list and the one in use is underlined; an alert opens on the menu its design is in.
- [ ] The grid scrolls; clicking a tile changes the design and moves the highlight.
- [ ] Legacy painted art (Overpower, Revenge, Victory Rush, Battle Shout) is bright at 100 % opacity and dims with the slider.
- [ ] Painted art sits around and above the character, never over it.
- [ ] Each shape draws on one alert: Ring, Side arcs, Pulsing frame, Bar, Screen edges. Four game arts draw.

### Placing alerts

- [ ] `/rb move` (or Move) labels each alert; drag one, `/reload`, it stays. Reset position on its page puts it back. A glow-only alert has no label.

### Sounds

- [ ] A new profile is silent: "Play sounds" off, every alert's sound None, crit sound None.
- [ ] A sound list holds the ten game sounds, then class spell sounds ("Mage: Frost Nova" ...), and scrolls with the wheel.
- [ ] Press Play down the list. Note any that is silent, wrong for its name, or too long. (About 100; do a sample of each class if short of time.)
- [ ] `/rb sounds` turns all sounds on and off; `/rb crit bell` sets and plays the crit sound.

### Macros

- [ ] Tabs All / Arms / Fury / Protection filter the list; the page opens on your own spec's tab.
- [ ] Each macro row shows its main spell's icon (Death Wish for RB Death Wish, Battle Shout for RB Rage Shout).
- [ ] The page lists only macros whose spells the warrior knows. Each text box fits its text exactly, and the text can be selected and copied but not edited.
- [ ] Create adds `RB <name>` to the character macros; the button turns to Created, and to Exists after `/reload`.
- [ ] With the page open, deleting that macro in the game's macro window turns the row back by itself.
- [ ] With no shield carried, the shield macros say "Needs a shield" and Create is off; putting a shield in the bags turns them on by itself.
- [ ] Press each created macro from each stance (see Part 3 for the ones that need a fight).

### Consumables

- [ ] The page lists Flask, Elixirs, Food, On the weapon, In the fight, Enchants, numbered best first; Damage and Tank tabs switch the lists; a Protection warrior opens on Tank.
- [ ] Every row has an icon and the item's name; none shows a question mark or stays blank (a blank one doesn't exist on this client: tell me which).
- [ ] Under each crafted item: who makes it and at what skill ("Alchemy (300)"), then "Needs:" with its materials and counts. Enchants show Enchanting and their materials.
- [ ] With the auction house open, shift-click a material (or an item's row): its name lands in the search box. With the auction house closed, it goes into the chat line as a link.
- [ ] Hovering a row shows the game's tooltip. Compare a few with the note beside the name: they should agree.
- [ ] Items you carry show "x3" and so on. No prices anywhere; a red line under Flask says flasks are expensive.
- [ ] Every material has its own small icon; the Damage tab shows the Berserker Stance icon and Tank the Defensive Stance icon; "Small extras" lists scrolls, armor kits, the shield spike and so on.
- [ ] Forever, if you have them: drink Elixir of the Grizzly and Elixir of the Mongoose together. Do both buffs stay, and does crit go up by 4%? Same question for Grizzly with Elixir of Greater Strength. Nobody has published this; your answer fixes the order.
- [ ] Items marked "unconfirmed on Forever" (R.O.I.D.S., Ground Scorpok Assay, Gordok Green Grog, Rumsey Rum): tell me if you know they can or can't be had.
- [ ] On Forever the lists hold Forever's items (Elixir of the Grizzly, Frenzy Potions ...); on Era the Classic ones (Elixir of Giants, Juju Power ...).

### Profiles

- [ ] The page scrolls; the status line and Reset stay put.
- [ ] Create, copy, rename, delete (asks first), switch. A blank or taken name shows an error.
- [ ] **Start from** = Protection + New: Revenge, Sunder and Taunt are on, Overpower is off. **Empty**: every alert off.
- [ ] Change one alert's design and position, then **Apply to current profile** with Fury: it asks first, and only which alerts are on changes.
- [ ] **Export** shows text; a click selects it and Ctrl+C copies it. Paste it under a new name with **Import**: an identical profile appears. Pasting "hello" says it isn't a Rageborn profile.
- [ ] Map your talent tree to a profile, `/reload`: the character switches to it with a chat line.
- [ ] `/reload` keeps every change made in Part 2.

## Part 3: one enemy (10 minutes)

Use a mob your level. This is also the probe's fight: do steps 3–6 of `docs/probe-results.md` here.

- [ ] **Overpower** after the target dodges, and after a Rend tick (Bloodthrill); gone when used or after 5 s.
- [ ] **Revenge** after a block, dodge or parry in Defensive Stance.
- [ ] **Execute** under 20 % target health. **Victory Rush** after the kill, for 20 s.
- [ ] **Interrupt** while a caster mob casts and Pummel or Shield Bash is ready.
- [ ] **Battle Shout** when missing, and again 3 s before it runs out; quiet while resting or mounted.
- [ ] **Gore Drinker** (8 s, after Bloodthirst, Bloodrage, Enrage ...) and **Enrage** (12 s): the alert appears with the proc and its timer matches the buff.
- [ ] Press each cooldown you have: Shield Wall, Last Stand, Shield Block, Retaliation, Recklessness, Death Wish, Sweeping Strikes, Berserker Rage, Bloodrage. Each shows from the press and its timer ends when the effect does.
- [ ] **Low health** under 35 % with Shield Wall or Last Stand ready.
- [ ] **Button glow:** the Overpower button glows with its proc, on your bars (EllesmereUI). A macro with `/cast Overpower` glows too. Try all four glow kinds and a colour.
- [ ] Switch stance mid-fight, then get a Revenge proc: does the button on the new bar page glow? (Known risk.)
- [ ] No "action blocked" message at any point.
- [ ] Turn on **Sunder**, **Rend missing**, **Thunder Clap missing**, **Rage dump**:
  - [ ] Sunder shows its stacks, and pulses fast at 5 s left.
  - [ ] "Rend missing" shows on a mob without Rend, hides when applied, returns when it falls off. Same for Thunder Clap.
  - [ ] At 80 rage Heroic Strike glows, and stops when you queue it.
- [ ] A critical hit plays the crit sound (set one first); a normal hit doesn't.
- [ ] With the Vanguard talent, the two RB Charge macros read `stance:1/2` and Charge from Defensive Stance; without it, `stance:1`.
- [ ] Reckless Swings (turn it on): shows for 8 s from the press.
- [ ] Macros in a fight: Charge/Intercept by stance, Overpower and Pummel from any stance, Shield Bash / Shield Wall / Shield Block equip the shield, Bloodrage + Battle Shout, Bloodrage + Death Wish, Hamstring, Mocking Blow, Berserker Rage, mouseover Taunt and mouseover Charge.
- [ ] Create a macro in combat: refused with a message. Switch profile in combat: refused.

## Part 4: several enemies (5 minutes)

- [ ] Pull two or more: **Demo Shout: pull** shows and its button glows; one mob alone doesn't. After shouting it stays away for 30 s. Its slider (2–6) changes when it appears.
- [ ] With Rage dump on and two or more mobs, **Cleave** glows; with one left it goes back to Heroic Strike.
- [ ] With enemy nameplates off, neither of these appears (known limit).

## Part 5: when you can (group, PvP, another character)

- [ ] **Taunt** (turn it on), in a group: when your target turns to a party member the alert shows; gone when the mob is back on you.
- [ ] **Racial:** its button glows only when it helps and is ready — human stunned (Will to Survive), gnome rooted or slowed, undead feared or charmed, dwarf poisoned or diseased, orc cursed (Shatter Curse). Nothing is drawn on screen.
- [ ] **Berserker Rage** when feared in Berserker Stance: its alert shows and its button glows.
- [ ] Respec so another tree leads: the mapped profile switches (after combat if you were fighting).
- [ ] With EllesmereUI Action Bars disabled: glows on the default bars. (Dominos, Bartender4, ElvUI are not installed here: untested.)
- [ ] On a non-warrior: no Rageborn frames, no minimap button, no errors; `/rb` prints "Rageborn only works on a warrior."
- [ ] A full fight (pull, stance dance, procs, a defensive, a kill) with no error popup and BugSack empty.

## When something doesn't show

| What | Run this, and send me the output |
|---|---|
| Gore Drinker or Enrage never appears | With the buff up: `/dump C_UnitAuras.GetAuraDataByIndex("player", 1, "HELPFUL")`, raising 1 until you find it. I need its `name` and `spellId`. |
| An alert for a spell you have is missing from the list | `/dump IsPlayerSpell(12345)` with the spell's ID from its tooltip, and tell me the ID. |
| Racial never glows | Your race, and with the stun/root/fear on you: `/dump C_LossOfControl.GetActiveLossOfControlData(1)`. |
| Slowed gnome never glows | While slowed: `/dump GetUnitSpeed("player")`. |
| Rend / Thunder Clap missing, or Sunder, never appears | In the fight: `/dump C_UnitAuras.GetAuraDataByIndex("target", 1, "HARMFUL")`. |
| Demo Shout: pull never appears | `/dump #C_NamePlate.GetNamePlates()` with the mobs on you. |
| Berserker Rage alert doesn't show when sapped or gouged | With the effect on you: `/dump C_LossOfControl.GetActiveLossOfControlData(1)`. I need its `locType`. |
| Spec profile doesn't switch | `/dump GetTalentTabInfo(1)` and `/dump IsPlayerSpell(23881)` (Bloodthirst), `12294` (Mortal Strike), `23922` (Shield Slam). |
| A sound is silent | Its name in the list. |
| A button doesn't glow | Which bar addon, and whether it is a spell or a macro on the button. |

## Afterwards

- [ ] `/reload` (writes the probe log), then tell Claude: it fills in `docs/probe-results.md`, fixes what failed, and removes `RagebornProbe`.
- [ ] Wrong spell IDs or durations go into `docs/probe-results.md` under corrections.

## Classic Era / Hardcore (a second, shorter session)

The Era client has never run this addon either. On an Era or Hardcore warrior:

- [ ] `/console scriptErrors 1`, log in: no Lua error; `/rb` opens the window; the minimap button's ring sits centred on the icon.
- [ ] The left list shows no Forever alerts (Gore Drinker, Reckless Swings, Victory Rush unless SoD) and no question-mark icons.
- [ ] Parts 1 and 2 of the Forever route work the same: fonts, Gallery, colour wheel (if nothing opens when you click Colour, tell me), sounds, macros, profiles.
- [ ] Spec profiles switch by talent tab points.
- [ ] One fight: Overpower after a dodge, Revenge after a block, Execute under 20 %, Battle Shout reminder with a 2-minute timer, Shield Wall 10 s, Shield Block 5 s.
- [ ] Button glow works; if the Proc loop and Marching ants kinds look like the Pulsing border, the Era client lacks that art (expected fallback).
- [ ] Enrage (if talented) shows for 12 s.
