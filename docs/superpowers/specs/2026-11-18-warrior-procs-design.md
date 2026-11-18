# Rageborn — design

Date: 2026-11-18. Target: WoW Forever only (Interface 16001, `## AllowLoadGameType: camelot`).
Items marked **[call]** were decided by the designer, not the owner, and can be overruled.

## Intent

A warrior-only addon, **Rageborn**, that shows procs, reminders and active cooldowns as
on-screen alerts, makes the matching action buttons (including macro buttons) glow, and offers
a page of ready-made warrior macros.

Why: SpellActivationOverlay and GlowingBars already do a basic version, but with little control
over the look. The owner wants MageProcs-level customization for a warrior: many arts to pick
from, per alert, with everything adjustable.

## Goals

- On-screen alerts for the events in "Alerts" below, each with its own style and settings.
- Two art families: the game's own proc overlays, and our own animated shape styles.
- Button glows with a choice of animation and colour, working on macros.
- Works on EllesmereUI action bars (the owner's), the default bars, and other bar addons.
- A macros page: ready-made warrior macros the player adds to the game's macro list.
- Fully own code: own settings window with live preview, own glow animations, own profiles.
  No libraries (no Ace3, LibCustomGlow, LibSharedMedia).

## Non-goals

- Other classes. The addon does nothing if the player is not a warrior.
- A HUD. The owner does not want one: most players already run unit-frame and bar addons. So no
  rage bar, swing timer, aggro gauge, "next best ability" suggestion, momentum meter, combat
  text or weapon-skill bars.
- Other clients (Retail, Classic).
- Art that changes with stack count (nothing a Forever warrior has needs it).
- Loading the player's own image files from a folder. **[call]** (Painted art ships with the addon.)
- Translations. All texts live in one table (`Locale.lua`, enUS) so they can be added later. **[call]**
- Profile import/export strings. **[call]**
- Custom sound files; sounds come from a fixed list of game sounds. **[call]**

## Anti-goals

- Copying code or textures from MageProcs (All Rights Reserved) or from any other installed
  addon (Max Warrior Suite, Ultimate Warrior, Forever Warrior HUD: licences not checked).
  Ideas only.
- Tainting action bars: never call Blizzard's glow functions on other addons' or secure
  buttons, never change protected frames in combat.
- An alert that lies: when something can't be read in combat, show an estimate marked by
  design (a timer from the known duration), never a guessed proc.

## Constraints (from reading MageProcs, SpellActivationOverlay, GlowingBars on this client)

- In combat the player's buffs are secret and the combat log is closed to addons.
- Spell usability is readable in combat; SpellActivationOverlay drives all four warrior procs
  from it on Forever.
- The player's own casts are readable through `UNIT_SPELLCAST_SUCCEEDED` (MageProcs relies on
  it; it guards against the spell ID being secret).
- Raw health is secret in combat, but Ultimate Warrior reads a plain health percent through
  `UnitHealthPercent(unit, false, CurveConstants.ScaleTo100)`. Expected to work for the player
  too; the probe confirms it.
- Dodges, parries and blocks are visible without the combat log through `UNIT_COMBAT` on the
  player and the target, and kills through `PARTY_KILL` (Max Warrior Suite's method).
- If "usable" itself ever comes back secret, a texture can still follow it with
  `SetAlphaFromBoolean` (Ultimate Warrior's fallback).
- Forever-specific: the Bloodthrill talent (buff 1289682, a Rend tick opens Overpower for 5 s)
  and the Spearing Strike ability exist. Blizzard's own button glow fires for Overpower.
- Sounds must be game sounds: Blizzard's addon policy is reported to block playing sound files
  from the addons folder.
- Never ask a texture for `"TRILINEAR"` filtering: MageProcs notes it crashes the Forever client.
- Secret values must be tested with `issecretvalue` (guarded, it may not exist) before any
  comparison or arithmetic.
- Present in the client (used by installed addons): atlases
  `UI-HUD-ActionBar-Proc-Loop-Flipbook` and `rotationhelper_ants_flipbook`; about 90 proc
  overlay textures by file ID (list in `SpellActivationOverlay/textures/texname.lua` under
  `_forever_/Interface/AddOns`). A file may still be missing: test each with a hidden
  texture's `SetTexture` under `pcall` and offer only those that load.

## Approaches considered

| | Approach | Trade-off |
|---|---|---|
| A | Standalone, with Ace3 + LibCustomGlow + LibSharedMedia | Least code, proven parts; generic-looking settings window, preview outside the window |
| **B** | **Standalone, everything our own** | **Nicest result and full control; about double the work, mostly in the settings window** |
| C | Extension on SpellActivationOverlay + GlowingBars | Ruled out: fixed art and positions, breaks when they update |

The owner picked **B**.

## Alerts

Each alert is one entry in a data table (`Data.lua`); the engine reads the fields, so adding an
alert means adding an entry and its texts.

| Key | Kind | Shown when | How it is read |
|---|---|---|---|
| overpower, revenge, execute, victoryRush | `usable` | the ability can be pressed | spell usable and off cooldown |
| battleShout | `reminder` | the buff is missing, or runs out within N seconds (default 3 **[call]**) | out of combat: the aura. In combat: a timer from the last seen expiry or the player's own cast |
| one per defensive: Shield Wall, Last Stand, Shield Block, Retaliation | `active` | the player pressed it, until its duration ends | own cast + duration from the data table; the real duration replaces it when read from the aura out of combat |
| one per offensive: Recklessness, Death Wish, Sweeping Strikes, Berserker Rage, Bloodrage | `active` | same | same |
| lowHealth | `lowHealth` | health below a threshold (default 35 % **[call]**) | health percent; fallbacks decided by the probe, see below |
| interrupt | `usable` | the target is casting or channelling and Pummel or Shield Bash can be pressed | target cast info + usability |
| shieldBlock | `usable` | in combat, shield equipped, Shield Block ready | usability + cooldown + equipped item type |
| queued | `active` | Heroic Strike or Cleave is queued for the next swing | the game's "current action" state of the spell |
| sunder, rend, demoShout, thunderClap | `debuff` | on the target: stacks / time left | target debuffs — may be secret in combat: only built if the probe shows they are readable |

Rules:

- `usable`: lacking only rage still counts as the proc being up **[call]**.
- Stance hint: Overpower and Revenge are also tracked from the dodge / parry / block events
  (5 s window). When the proc is open but the stance is wrong, the alert shows with the icon of
  the stance to switch to. One setting per alert turns the hint off.
- `active` and `usable` alerts for a spell the character doesn't know are hidden everywhere,
  including the settings list.
- Which cooldowns appear is the player's choice: each has its own on/off. Defaults: the four
  proc alerts, interrupt, Battle Shout, Shield Wall, Last Stand, Recklessness, Death Wish on; the rest
  off. **[call]**
- Battle Shout out of combat is drawn at half opacity (Retail behaviour) and hidden while
  resting, mounted or dead. **[call]**
- Spell IDs and durations start from Classic values (all ranks listed per spell) and **must be
  checked in game**; Victory Rush is 402927 on Forever per SpellActivationOverlay. Resolve the
  highest rank the character knows.

### Low health

The intent is "warn me to press a defensive when I'm low and one is ready".

- Expected (health percent readable in combat): full version — shows only when at least one
  enabled defensive is off cooldown, with sound.
- If health is secret: visual-only version — a red screen-edge vignette whose opacity is driven
  by the hidden value (a step curve passed to the health-percent API, result handed straight to
  `SetAlpha`). No sound, no cooldown check, and the settings say so.
- If neither works: the alert is left out and the settings say why.

## Probe (first build step, throwaway)

A tiny addon the owner runs on the warrior, in and out of combat, printing for each: is it
readable, secret, or missing.

- `UnitHealth("player")`, `UnitHealthMax`, `UnitHealthPercent` with `CurveConstants.ScaleTo100`
- `UNIT_COMBAT` on player and target (dodge / parry / block), `PARTY_KILL`
- target debuffs (Sunder Armor stacks, Rend time left) and the target's cast info
- the "queued" state of Heroic Strike
- `C_Spell.IsSpellUsable` and `C_Spell.GetSpellCooldown` for Overpower, Revenge, Execute
- the spell ID in `UNIT_SPELLCAST_SUCCEEDED`
- `C_UnitAuras.GetPlayerAuraBySpellID` for Battle Shout
- existence of the two glow atlases and of each overlay file ID

Its results settle the low-health version and confirm the reading methods above. If a method
other than low health fails, stop and bring it back to the owner.

## Alert look

Three families, chosen per alert in the gallery (below):

- **Painted art** — our own painted emblems, generated with Codex's image tool at the owner's
  request (2026-11-18), several options per proc. Painted on pure black and drawn with additive
  blending, so black is transparent. Shipped as 256x256 TGA in `Media/Art/`. **Placement rule
  (owner, 2026-11-18): proc art goes around and above the character, never over it**, like
  SpellActivationOverlay and MageProcs. So painted art comes in two layouts: `sides` (a tall
  piece drawn left of the character and mirrored on the right, 256x512) and `top` (a wide
  piece arched above the head, 512x256). The spread setting moves side pieces apart and top
  pieces up. The earlier centred emblems (256x256) are kept only as small `top` options.
  The same rule sets the default positions of every proc style: nothing is drawn within the
  middle of the screen where the character stands. Any painted art
  can be put on any alert; an alert's own options are listed first. Tint, scale, opacity.
  The first painted option is the default style of an alert that has one. **[call]**

- **Game art** — every proc overlay the client has, any art on any alert. Layout per art:
  both sides (mirrored), top, or single. Tint, scale, opacity, spread between the sides.
- **Shape styles** — built in code from our own white textures, tinted at run time. First set
  **[call]**: `ring` (icon in a ring with a timer sweep), `arcs` (two side arcs), `frame`
  (pulsing square frame around the icon), `bar` (icon plus a draining bar), `vignette`
  (screen-edge glow, the default for lowHealth). A style is one builder function registered in
  a catalog; adding a style must not touch the engine.
- Textures are generated by a script kept in the repo (`tools/`), written as 32-bit TGA with
  power-of-two sizes. Shapes: ring, arc, soft glow, frame, bar, spark, edge gradient, round
  mask, plus warrior ones: crossed blades, shield, rage drop.

Per-alert settings: enabled, style, colour, size, opacity, position, spread (two-sided styles),
show icon / name / timer, sound, combat only, and the glow settings below.

Behaviour: pop in with a short scale-up then a slow breathe; fade out when the alert ends;
timer text for anything with a known end.

Placement: each alert has its own position, dragged on screen in a "move" mode, with a reset.
Defaults place `usable` alerts around the screen centre and `active` ones in a row below it.
**[call]**

### Gallery

The owner asked for a menu like MageProcs' that shows every design. A Gallery page in the
settings window: a scrolling grid of large animated previews of every style, grouped Painted /
Shapes / Game art, drawn in the selected alert's colour. A dropdown at the top picks which
alert the gallery is for; clicking a design applies it to that alert at once and marks it as
the current one. The alert page has a "Browse designs" button that opens the gallery for that
alert. Previews animate only while the page is visible.

## Button glows

- For each alert with a spell to press, glow every action button that casts it while the alert
  is up. Per alert: on/off, glow style, colour.
- Glow styles **[call]**: the Retail proc loop (flipbook atlas), marching ants (flipbook atlas),
  a code-drawn pulsing border, a code-drawn rotating corner highlight. All tintable. Each is
  our own frame parented to the button, pooled and reused.
- Macros: a macro button glows when the spell it currently shows is the alert's spell. A
  setting "glow for every spell in a macro" also matches any `/cast` or `/use` line naming the
  spell (conditions in `[]`, rank suffixes and `/castsequence` lists stripped).
- Finding buttons: one table of button-name patterns per bar addon — default bars,
  EllesmereUI (`EABButton<n>`), Dominos, Bartender4, ElvUI — read at login and when bars
  change. The action slot comes from the button itself. A bar addon that isn't installed costs
  nothing; a new one is one new entry. Tested on EllesmereUI and the default bars; the others
  are built from the names GlowingBars uses and are untested.
- Button contents are re-read on action-bar change events, never per frame.

## Macros page

A page in the settings window listing ready-made warrior macros. Each row: name, what it does,
the macro text, and a button that adds it to the game's macro list (character macros; refused
with a message in combat or when the list is full). Macros are plain data in one file.

First set **[call]**: Charge / Intercept by stance; stance swap + ability (Overpower from any
stance, Pummel from any stance); equip shield + Shield Bash; equip shield + Shield Wall;
Bloodrage + Battle Shout; Taunt on mouseover, else target. Only macros whose spells the
character knows are offered; the builder verifies each in game.

## Settings

- Own window, opened by `/rb` and from the game's addon list and compartment button.
- Left: the alerts, grouped Procs / Reminders / Defensives / Offensives / Low health / Target. A separate Macros page.
  Right: the selected alert's settings with a live preview of its style inside the window.
- A general page: master on/off, global scale, move mode, test all, reset.
- Profiles: settings saved per account in named profiles; each character picks one (default:
  its own). Create, copy from, rename, delete, reset.
- Saved data is merged over defaults on load, so new settings appear without wiping old ones.

## Layout

Folder `Rageborn/` in the repo, deployed by copying to
`_forever_/Interface/AddOns` with a script. Files by responsibility: Locale, Util, Data,
Database (defaults, merge, profiles), Detect, Engine, Styles, Alerts, Glow, Bars, Mover,
Sounds, Macros, Options, Init.

Icon: the owner's own image "G3 fire close-up" — the bottom-left quarter of
`docs/icons/gpt/source.png` — cropped square and exported as a 64x64 TGA into `Media/`.

Status: design approved by the owner on 2026-11-18 ("begin working on the addon").

## Checks

- Logic that doesn't touch the game runs under the system `lua5.1` with a small stub: macro
  parsing, defaults merge, timer bookkeeping.
- Everything else is checked in game from a written checklist; `/rb test` shows every enabled
  alert and glow without needing the proc.

## Left to the builder

- Exact spell IDs, ranks and durations (verify in game).
- The API names for health percent and curves on this build (verify against the `forever`
  branch of Gethe/wow-ui-source).
- Internal structure of each file, the exact look of each shape style, default positions and
  colours, the sound list.
