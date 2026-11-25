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
