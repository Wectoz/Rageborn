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
