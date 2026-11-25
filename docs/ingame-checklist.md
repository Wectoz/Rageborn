# In-game checklist

Run `/console scriptErrors 1` first so Lua errors show. Tick a line once it is seen working.

## Task 7: alerts on screen, sounds

- [ ] The addon loads on the warrior with no Lua error.
- [ ] `/rb test` shows every enabled alert in its default style with a running timer; `/rb test` again hides them.
- [ ] Painted art sits around and above the character, not over it.
- [ ] Fighting a mob: Overpower appears after a dodge and disappears when used or after 5 s.
- [ ] Revenge appears after a block, dodge or parry in Defensive Stance.
- [ ] Execute appears under 20 % target health.
- [ ] Victory Rush appears after a kill.
- [ ] Each of the ten sounds plays (set one with `/run RagebornDB.profiles[next(RagebornDB.profiles)].alerts.overpower.sound = "raidWarning"`, then `/reload` and `/rb test`; keys are in `Rageborn/Sounds.lua`).

## Task 8: mover

- [ ] `/rb move` shows the alerts with a label on each; drag a label, `/reload`, the alert stays where it was dropped.
- [ ] `/rb reset` returns the alerts to their default places (per-alert reset comes with the settings window).
- [ ] Entering combat ends move mode by itself.

## Sounds

- [ ] `/rb crit` lists the sounds; `/rb crit bell` plays the bell and says it is set.
- [ ] A critical hit on the target plays that sound; a normal hit doesn't.
- [ ] `/rb sounds` turns every sound off, and on again.

## Task 10: settings window

- [ ] `/rb` opens the window; it drags by the title bar, closes on Escape, and reopens where it was left after `/reload`.
- [ ] The left list shows only alerts the warrior knows, grouped; clicking one opens its page with a moving preview.
- [ ] On one alert, change every control (enabled, colour, tint, size, opacity, spread, side, icon, name, timer, sound + Play, combat only, stance hint, glow, glow kind, glow colour): the preview follows, and so does the real alert under `/rb test`.
- [ ] Battle Shout and Low health show their threshold slider; other alerts don't.
- [ ] Browse designs opens the Gallery for that alert; the grid scrolls; clicking a tile changes the design and moves the highlight.
- [ ] General: enable, size of all alerts, play sounds, critical hit sound + Play, glow for every macro spell, Move, Test all, Reset everything (asks first).
- [ ] Profiles: create, copy, rename, delete (asks first), switch; a blank or taken name shows an error; switching in combat is refused.
- [ ] The game's Options > AddOns list has Rageborn with a button that opens the window.
- [ ] `/reload` keeps every change.

## Task 9: button glow

- [ ] The Overpower button glows while the proc is up, on the bars in use (EllesmereUI) and on the default bars.
- [ ] A macro with `/cast Overpower` glows too; with "Glow for every spell in a macro" on, a macro naming the spell further down glows as well.
- [ ] All four glow kinds draw and take the chosen colour: Proc loop, Marching ants, Pulsing border, Rotating corners.
- [ ] No "action blocked" message when a glow appears or disappears in combat.
- [ ] Switch stance in a fight, then get a Revenge proc: does the Revenge button on the new bar page glow? (Known risk: buttons are only re-read after combat.)

## Task 11: macros page

- [ ] The Macros page lists only macros whose spells the warrior knows; each shows its text, which can be selected and copied but not edited.
- [ ] Create adds `RB <name>` to the character macros; the button turns to Created, and to Exists after `/reload`.
- [ ] Each created macro works as described: Charge / Intercept by stance, Overpower and Pummel from any stance, Shield Bash and Shield Wall equip the shield (`[noworn:Shields]` and `/equipslot 17` are accepted by this client), Bloodrage + Battle Shout, Taunt on mouseover.
- [ ] Dragged to a bar, a created macro's button glows with its proc (RB Overpower with the Overpower proc).
- [ ] With no shield carried, the two shield macros show "Needs a shield" and Create is off.
- [ ] Create in combat is refused with a message; with 18 character macros it says the list is full.

## Task 12: every alert

For each: it appears when it should, disappears when it should, and its timer (where it has one) looks right. Turn the off-by-default ones on first.

- [ ] Overpower: after a target dodge and after a Rend tick (Bloodthrill); gone when used or after 5 s.
- [ ] Revenge: after a block, dodge or parry in Defensive Stance; gone when used or after 5 s.
- [ ] Execute: target under 20 % health, Battle or Berserker Stance.
- [ ] Victory Rush: after a kill; gone when used or after 20 s.
- [ ] Interrupt: while the target casts and Pummel or Shield Bash is ready.
- [ ] Shield Block reminder: in combat, Defensive Stance, shield on, Shield Block ready.
- [ ] Battle Shout: missing, and again 3 s before it runs out; quiet while resting, mounted or dead.
- [ ] Queued swing: while Heroic Strike or Cleave is queued.
- [ ] Shield Wall (10 s), Last Stand (20 s), Shield Block active (5 s), Retaliation (15 s): shown from the press, timer runs down to the real end.
- [ ] Recklessness (15 s), Death Wish (30 s), Sweeping Strikes (20 s), Berserker Rage (10 s), Bloodrage (10 s): the same.
- [ ] Low health: under 35 % with Shield Wall or Last Stand ready; not when both are on cooldown.
- [ ] Sunder Armor, Rend, Demoralizing Shout, Thunder Clap on the target: shown with stacks or time left, or greyed out in the list if the client hides target debuffs.
- [ ] Any spell ID or duration that was wrong is noted in `docs/probe-results.md` under corrections.

## Task 12: designs, bars, the rest

- [ ] Each shape design draws on one alert: Ring, Side arcs, Pulsing frame, Bar, Screen edges.
- [ ] Four game arts picked from the Gallery draw, and four painted ones.
- [ ] Glows on EllesmereUI bars; then with EllesmereUI Action Bars disabled, on the default bars. (Dominos, Bartender4 and ElvUI are not installed here: untested.)
- [ ] On a non-warrior: no Rageborn frames, no errors, `/rb` prints "Rageborn only works on a warrior."
- [ ] A full fight (pull, stance dance, every proc, a defensive, death or kill) with `/console scriptErrors 1`: no error popup, BugSack empty, no "action blocked".
- [ ] The probe's fight steps are run (`docs/probe-results.md`) before `RagebornProbe` is deleted.

## Legacy menu and colours

- [ ] Gallery: the Modern and Legacy buttons switch the list; the menu in use is underlined; an alert opens on the menu its design is in.
- [ ] Legacy painted art (Overpower, Revenge, Victory Rush, Battle Shout) is bright at 100 % opacity and dims with the Opacity slider.
- [ ] On a painted design, Colour opens the game's colour wheel; picking a colour recolours the art live and ticks Tint; Cancel puts the art back; unticking Tint returns its own colours.

## Settings window: red look, fonts, size

- [ ] The window is oxblood and bone: red title bar (darker at the foot), solid red selected row, red ticks; no orange left anywhere.
- [ ] General, bottom row: Window size 70–130 % resizes the window and it stays where it was; `/reload` keeps size and place.
- [ ] Headings and Text each offer Friz Quadrata, Morpheus, Skurri, Arial Narrow; every page changes at once, nothing is cut off or overlaps in any of them. The three lists open upwards.
- [ ] The alert page shows the design's menu after its name, e.g. "Overpower: sides 1 (Legacy)".
- [ ] Macros page: each text box fits its text exactly; with the page open, creating or deleting a macro in the game's macro window, or moving a shield in or out of the bags, updates the rows by itself.

## Racial glow and Demo Shout on a pull

- [ ] The racial's button glows only when it would help and is ready: human stunned, gnome rooted or slowed, undead feared or charmed, dwarf poisoned or diseased. It stops when pressed or when the effect ends; nothing is drawn on screen for it.
- [ ] The racial's spell ID is right on this client (the alert "Racial ability" is listed under Defensives), and a stun, root, slow or fear is actually noticed in combat.
- [ ] With enemy nameplates on, pulling two or more mobs shows "Demo Shout: pull" and glows its button; one mob doesn't. After shouting it stays away for 30 s.
- [ ] Its "Enemies in the fight, at least" slider (2–6) changes when it appears.
- [ ] With enemy nameplates off it never appears (known limit).

## Show on screen, new macros, minimap button

- [ ] Minimap button appears on the warrior with the ring centred on the icon; left click opens and closes the settings, right click toggles test mode, the tooltip shows.
- [ ] Drag it around the minimap; `/reload` keeps its place; General > "Minimap button" hides and shows it.
- [ ] Racial alert page: "Show on screen" is off and the appearance controls are greyed; in test mode nothing is drawn for it but its button glows. Ticking it makes the alert visible.
- [ ] Macros page lists the six new macros when their spells are known; each works from each stance as described (mouseover Charge/Intercept, Bloodrage + Death Wish, Berserker Rage, Mocking Blow, Hamstring, Shield Block with shield swap).

## New combat alerts

- [ ] Sunder: stacks show; at 5 s left the alert pulses fast; its slider (1-15 s) moves that point.
- [ ] "Rend missing" and "Thunder Clap missing" (turn them on): shown on a mob without the debuff, hidden once applied, back when it falls off; nothing with no target, a friendly or dead target, or out of combat.
- [ ] Feared in Berserker Stance with Berserker Rage ready: its alert shows and its button glows.
- [ ] Rage dump (turn it on): at 80 rage Heroic Strike glows, and goes out when queued; with two or more mobs Cleave glows instead; its slider (30-100) moves the point.
- [ ] Taunt (turn it on), in a group: when your target turns to a party member the alert shows; gone when the mob is back on you.

## Presets, sharing, spec profiles

- [ ] Profiles page scrolls; "Start from" = Protection + New gives a profile with Revenge, Sunder and Taunt on and Overpower off; Empty gives one with every alert off.
- [ ] "Apply to current profile" asks first and changes only which alerts are on; designs and positions stay.
- [ ] Export shows text that selects and copies; pasting it under a new name with Import creates an identical profile; pasting junk says it isn't a Rageborn profile.
- [ ] Map a talent tree to a profile, `/reload`: the character switches to it with a chat line; a respec switches again (after combat if in a fight). If nothing happens: `/dump GetTalentTabInfo(1)`.

## Sounds

- [ ] A new profile is silent: "Play sounds" is off, every alert's sound is None, the crit sound is None.
- [ ] Every sound list (each alert, and the crit sound) offers spell sounds of all nine classes after the ten game sounds; the list scrolls with the wheel. Press Play on each: note any that is silent, wrong, or too long.

## Gore Drinker, Enrage, descriptions, more sounds

- [ ] Every alert page has one line under its name saying what it is: "Press now", "Active effect", "Reminder", "On the target" or "Warning".
- [ ] Gore Drinker and Enrage are listed under Procs (only if the talent is taken); their pages have no Button glow section.
- [ ] When Gore Drinker procs, its alert appears and its timer matches the buff; same for Enrage. If Gore Drinker never shows: with the buff up, run `/dump C_UnitAuras.GetAuraDataByIndex("player", 1, "HELPFUL")` for each buff slot and note its name and spellId.
- [ ] Sound lists now also hold later-expansion sounds (Hot Streak, Shockwave, Devastate, Lava Burst, Death Knight sounds ...): press Play on each.
- [ ] Spec profiles: with a tree mapped to a profile, `/reload` switches to it (Forever talents are read from key talents known).
