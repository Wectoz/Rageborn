# Rageborn · Settings window

An 860 × 560 warrior settings window for Forever. The three companion PNGs are 2× proofs, not texture atlases. Build the chrome with frames, font strings and solid textures. Only the icon and preview wells contain illustration. The proofs show an English-speaking warrior with a mock painted catalogue, white alert tint, and a gold button-glow tint; they do not imply those designs are already installed.

## What makes it Rageborn

- The shipped fire icon identifies the addon once, in the title bar. The only repeated ember mark is a selection or an enabled check, not gold trim around every control.
- The live preview gives the warrior a clear centre: painted slashes flank the implied character or arch above it. The same composition is identifiable at tile size.
- The rail separates what the warrior *tracks* from what the player *does*: alerts scroll by combat role; Gallery, Macros and Profiles stay within reach even at the bottom of Target.

## Drawing contract

All boxes are `x,y,w,h`, in logical pixels from the window's top left; use `TOPLEFT, dx, -dy`. Borders are inside the box. Omitted fill = transparent `#00000000`. No backdrop transparency behind text, bevel, glow on chrome, corner treatment, shadow or decorative gradient. Colour notation is **RRGGBBAA**, not WoW inline ARGB; divide channels by 255 for texture/font calls.

| Token | RGBA | Use |
|---|---|---|
| Body | `#17191BFF` | Main field |
| Well | `#121416FF` | Rail, preview, code, input |
| Cap | `#202325FF` | Title bar, disabled controls, messages |
| Control | `#292C2EFF` | Enabled button/dropdown, scrollbar track |
| Hover | `#34383AFF` | Hot row or control |
| Rule | `#474A4AFF` | Dividers and resting borders |
| Quiet | `#858784FF` | Disabled text, scroll thumb |
| Secondary | `#B8B6AEFF` | Captions, help, slider progress |
| Ink | `#F3EEE4FF` | Primary text, focus outline, slider thumb |
| Ember | `#F47750FF` | Selected rail marker, selected tile border, checked box |
| Ember ground | `#352924FF` | Muted background behind selected row or tile label only |

Ember is the **only UI accent hue**. No ember headings, default buttons, slider fills, focus rings, warnings or destructive buttons. Errors say “Error:” and use an ink rule. User-selected swatches, the brand icon and inherent art colours are content, not UI semantics.

Use the client's Friz Quadrata for brand/page titles (18) and macro names/dialog titles (15). Use the game's standard legible sans face for rows/buttons/inputs (13), code and numeric values (12), uppercase headings/captions (11), miniature timer (10). Use whole strings from `ns.L`, not baked images. Text left aligned except numeric readouts (right). Typical line heights respectively 22, 19, 17, 15, 14, 12. No all-caps body copy. Full label on hover/focus if clipped; never ellipsize a macro body or an error. PNG typography and generated spell imagery stand in for the client's fonts/icons.

### Shell and navigation

| Region | Box | Detail |
|---|---|---|
| Root | 0,0,860,560 | 1 px Rule outline, dialog strata; first open centred |
| Title bar | 1,1,858,39 | Cap with bottom rule; drag anywhere except close |
| Icon / title / close | 12,8,24,24 / 46,7,300,26 / 817,4,36,32 | `Media/icon.tga`; “Rageborn”; centred ×, plain until hover |
| Rail / divider | 1,40,178,519 / 179,40,1,519 | Well / Rule |
| General / separator | 8,48,159,24 / 12,79,152,1 | Fixed |
| Alert list / scroll track | 8,84,159,356 / 171,84,4,356 | Clip both labels and hit regions; headings 22 high, rows 24 |
| Library separator / heading | 12,443,152,1 / 16,451,140,16 | Fixed |
| Gallery / Macros / Profiles | 8,473,159,24 / 8,499,159,24 / 8,525,159,24 | Fixed; one selection across whole rail |
| Content | 180,40,679,519 | Body. Safe area 200,53,640,490 |
| Page kicker / title | 200,53,408,15 / 200,69,408,25 | Alert: `GROUP  /  ALERT`; General: `SETTINGS`; tools: `LIBRARY` |

Open via `/rb`, compartment, or the **Open Rageborn** button in the game's addon settings. General first; reopen to the last valid page this session. Drag/release saves centre-relative offsets in the **current profile**; close never rolls changes back. Restore and clamp after opening, profile switch, display resize or scale change. Escape closes popup/picker/dialog first, then clears active edit focus, then closes window. Never steal ordinary gameplay keys while hidden or while the window lacks keyboard focus.

Populate in `Data.ALERTS` order within `Data.GROUPS`, not alphabetically. Display labels (not necessarily spell names):

| Group | Rows |
|---|---|
| Procs | Overpower, Revenge, Execute, Victory Rush, Interrupt |
| Reminders | Shield Block, Battle Shout, Queued swing |
| Defensives | Shield Wall, Last Stand, Shield Block active, Retaliation |
| Offensives | Recklessness, Death Wish, Sweeping Strikes, Berserker Rage, Bloodrage |
| Low health | Low health |
| Target | Sunder Armor, Rend, Demoralizing Shout, Thunder Clap |

Hide unknown-spell rows and headings with no rows. Low health has **no own spell**: use defensive eligibility and the probe result, not `Data.Known(lowHealth)`. Known but unreadable rows remain with their actual probe reason. An alert turned off by the player is **not** unavailable: keep its row operable. If the selected row disappears, go to General. Empty list: `No known alerts.` in a 151×40 wrapping field at 16,94. Non-warriors do not open this window.

### Widget recipes and input

Every interactive rectangle receives mouse input over the entire labelled area. Use an unprotected proxy for unavailable targets so the explanation is reachable on hover and keyboard focus. Common states: rest as specified; hover uses Hover fill or Secondary border; pressed uses Well fill and moves content down 1; focus draws a 1 px Ink outline just inside the perimeter, independent of selection; disabled uses Cap + Quiet, no hot/pressed action. Do not reduce the alpha of the whole panel. Enter/Space activate buttons and checkboxes. No symbol depends on a special font: tick, down arrow and × may use small white tinted glyph textures.

| Widget | Construction and exceptions |
|---|---|
| Rail row | Normal transparent, 13 Ink. Text x=16 for fixed rows, 25 for alerts, y+4. Hover fills row; selected Ember ground plus 3 px Ember left strip; selected-hover keeps strip. Unavailable: Quiet label, `!` at right, no select. Hover/focus tooltip with probe/gear reason; activation announces reason instead of navigating. Group headings x16,y+5; no click target. |
| Checkbox | H26. Box 14×14 at x,y+6; 1 px Rule, Well interior. On: solid Ember with dark 10×8 tick; off: empty. Label x+22,y+5. Hover outlines box in Ink; pressed offsets tick only. Disabled-on retains tick in Quiet against Cap. |
| Slider | H32; caption x,y and 40×15 right-aligned value at right. Track x,y+23,w,3, filled Secondary through thumb; 8×13 Ink thumb at y+18, travel `w-8`. Entire track clickable/draggable, arrows ±1 step, Home/End to bounds. Clamp before save, display rounded units, apply on step change only. Hover/drag thumb gets 1 px outline; disabled neutral thumb and readable last value. |
| Dropdown | H26, Control/Rule, text x+10,y+5; 7×4 down triangle 11 px from right. Same states as button; open: Ink border and reversed arrow. Popup Well/Rule, same width, 4 px padding, 24 px rows; at most 8 visible, scroll remainder. Anchor 2 px below or flip above; clamp to window. Selected row gets tick and Ember ground. Arrows move, Enter chooses, Escape/outside click dismisses without change. |
| Colour | 80×26 label + chip; chip x+52,y+3,28,20 with 1 px Quiet outline. Chip border Ink on hover/focus. Opens game `ColorPickerFrame` with current RGB, no alpha; opacity has its own slider. Preview during drag, cancel restores original RGB in both preview and DB. Disabled keeps sample, Quiet diagonal slash. Tooltip gives hex RGB. |
| Button / close | H26 unless given, Rule border, Control fill; 10 px left inset for text. Hover/press/focus/disable as above. Close uses transparent resting background, same hover/press, centred glyph. Toggle action uses explicit verb change, e.g. `Finish moving`. |
| Text input | H26; Well, Rule border; 8 px horizontal padding; 13 Ink. Hover Secondary border; focus Ink border + caret. Placeholder Secondary; invalid retains typed text, adjacent Error message. Enter submits; Escape discards edit. Disabled read-only with Quiet text. |
| Scrollbar | Visible rail 4 wide, 12-wide hit target centred on rail. Thumb Quiet, hover Secondary, dragging Ink; length `max(20, round(trackH*viewH/contentH))`, capped at trackH. Position proportional to scroll offset. No arrows. Track click pages one viewport; wheel 48 px/notch; clamp at ends, hide track and disable wheel if contents fit. Scroll focused item fully into view. |
| Gallery tile | 120×144; 120×120 square well with 1 px Rule inside; label 120×24 at y+120, inset 5. Hover Secondary border + Hover label; selected Ember border + Ember ground label. Focus outline inset 2 so selection survives. Pressed label shifts 1; missing styles omitted, not broken thumbnails. Long label: one line with ellipsis, full tooltip. |
| Section heading | H18, 11 Secondary uppercase; 1 px Rule across remaining width at y+8, starts 12 px beyond text. Pure label; no disclosure arrow or focus. |
| Inline info/error | Cap rectangle full allotted width, min H24; 2 px left rule (Secondary info, Ink error), text x+10,y+4, 13. Prefix `Info:` / `Error:`; expand by 17 px per wrap. Never colour alone. Replace old message on next attempt; clear on relevant edit/page change. No fading errors. |

Tab ring: rail (one stop; Up/Down traverse visible rows, Enter opens, Home/End jump; disabled reasons reachable) → page controls in section order below → close → rail. Shift+Tab reverses. Headings, static text, and scroll thumbs are not stops. Page activation places focus on first applicable control; on return to rail restore selected row. Skip hidden and non-actionable form controls; expose disabled reason via adjacent explanatory text or its enabled parent. Tab inside open popup/dialog stays there. Keyboard navigation is scoped to the active settings frame; do not leave global movement bindings captured after dismissal.

## Alert page · one template for all 22 alerts

Coordinates below are absolute. Standard checks/buttons/swatches H26, sliders H32. Use fixed slots: suppress inapplicable controls, do not move unrelated sliders as the player browses. Status line may grow into a scrollable form (see overflow below).

| Region | Boxes and content, in focus order |
|---|---|
| Identity | Shared kicker/title. Enabled check `200,103,160,26`; CURRENT DESIGN `200,139,400,14`; current style name `200,153,400,20`; Browse designs `200,177,124,26` opens Gallery targeting this alert. No second style dropdown. |
| Live preview | `622,54,218,142`, Well/Rule; LIVE PREVIEW `632,61,196,14`; art stage `632,79,198,107`. Noninteractive. |
| Appearance | Heading `200,212,640,18`; colour `200,239,80,26`; size `360,236,200,32`; opacity `590,236,250,32`; spread `200,278,200,32`; Icon `438,278,100,26`, Name `555,278,100,26`, Timer `685,278,110,26`. |
| Behaviour | Heading `200,322,640,18`; Sound label `200,347,48,18`; dropdown `250,342,150,26`; Play `408,342,54,26`; Combat only `483,342,145,26`; Stance hint `686,342,150,26`; optional threshold `200,368,262,30`. |
| Button glow | Heading `200,399,640,18`; Glow `200,423,150,26`; kind `360,423,200,26`; independent glow Colour `590,423,80,26`. |
| Status / actions | Optional message `200,461,640,30`; separator `200,499,640,1`; Move `200,511,72,26`, Reset position `280,511,120,26`, Test `408,511,64,26`. When moving, widen first button to 122 and shift following buttons +50. |

Settings write immediately; apply to this alert and refresh engine. Toggling Enabled changes live tracking, **not** the ability to edit or audition the design. Test invokes the test driver; don't enable tracking or manufacture a real proc. On Move enter the shared mover with labelled handles for enabled, positionable alerts. Dragging saves centre-relative X/Y; Reset position affects only this key. Combat ends move mode and disables Move with reason. For screen edges, omit size, spread, Move and Reset position; the screen perimeter is the anchor.

- Size and spread 50–200%, step 5%; opacity 0–100%, step 5%; store multipliers. Show spread for mirrored sides (and a painted top only if its builder actually implements vertical spread). Determine **effective layout**, not just `def.sides`: the default game overlay resolves per alert. Don't show a slider that does nothing. Show part toggles only for parts the builder draws; Timer only where there is a meaningful time. Stance hint only if `def.stances`. Battle Shout threshold “Warn before expiry” 1–15 s, step 1; Low health “Health below” 10–60%, step 1. Other alerts have no threshold.
- Sound lists `none` plus the registered game sound kits. Play only for an actual kit. Button glow section only when the engine has a press target; off disables kind/colour without dropping their values. Options in order: Proc loop, Marching ants, Pulsing border, Rotating corners. The general macro toggle affects matching, not the per-alert swatch.
- Low-health visual-only mode: keep threshold, show `LOWHEALTH_VISUAL_ONLY` inline, disable sound/Play and defensive-dependent glow; if unreadable entirely, disable navigation with `LOWHEALTH_UNAVAILABLE`. No simulated health presented as a live reading.
- Preview uses a **local** miniature scene: feed synthetic known-duration sample (Overpower: 5 s cycle; proof at 3.2 s). Preserve aspect and relative geometry; reserve the middle third for the player, put the optional small icon/timer below centre. Preview at 100% fits normal art in 158×102 centred in the stage; scale relative to that baseline and clip at the stage edges, so size changes remain visible. Apply tint, spread, opacity, parts and the style's own animation. No sounds or real action-bar mutations from a preview. For vignette, anchor edges to the preview well, **never** the `UIParent` host in the current world builder. Hide/update-stop on page exit.
- If saved art no longer loads, show resolved Ring and `Info: Saved design unavailable. Previewing Ring.` Do not overwrite the stored style until the user chooses another. If opacity is zero, retain the empty well and say `Info: Preview hidden at 0% opacity.`

## Gallery

Header as above. Label `200,106,75,18`, target dropdown `279,101,222,26`; together read **Designs for: Overpower**. Direct navigation restores last eligible target this session, otherwise first eligible alert. Browse designs overrides it. Changing target never changes either alert's style. Reset scroll to top on target change; selection applies immediately and stays on Gallery.

Grid viewport `200,148,626,395`, scroll rail `836,148,4,395`. For each non-empty family: heading `(200,Y,626,18)`; tile `(200+160*c,Y+22+156*r,120,144)`, c=0..3, r zero-based. Next heading Y = previous Y + 24 + 156 × number of tile rows. Start Y=148. Thus with three painted samples, Shapes starts at 328, tiles at 350, fifth shape at 506; Game art follows at 664. Do not stretch a sparse final row. Use the same preview rendering/scale for all tiles within a family, 4 px internal safety inset, fixed representative sample settings, selected alert's tint. A tile demonstrates the design independently of saved alert opacity or enabled state. Labels stay outside the animation.

Order: **Painted** (alert's own first, other registered art next; small former centred emblems only as overhead art) → **Shapes** (Ring, Side arcs, Pulsing frame, Bar, Screen edges) → **Game art** (this proc's own first, then available `ArtList` order). `Styles.lua` currently lists shape/game only; don't invent catalogue entries or ship a selectable static thumbnail. Mock names Slash trail, Flaming blade and Crossed arcs describe the supplied art direction. Omit empty families. No target: disable dropdown, replace grid with `No known alerts to design for.` No available designs: `No designs available for this alert.` On load failure after listing, refresh availability and report the fallback without applying a bogus style.

Tab: target → grid (one stop; initially current tile, otherwise first) → close. Arrow keys move by column/row within family then to next/previous family; Enter/Space applies like click; moving focus alone does not apply. Reuse preview frames; animate only visible tiles while page shown; stop all on hide. Clicking calls Apply/Refresh, moves border and label background together.

## Macros

Subtitle `200,103,640,22`: **Create character macros for spells you know.** Scroll viewport `200,140,624,403`; track `836,140,4,403`. Single column; no table header or horizontal scroll. Each row begins at Y (first 140); coordinates below assume one description line. Keep name, instructions, command body and action together.

| Part | Box |
|---|---|
| Separator / name | `200,Y,624,1` / `208,Y+10,516,21` |
| Create / description | `740,Y+10,76,26` / `208,Y+34,608,18` |
| Macro text | `208,Y+58,608,17+15*n`, Well/Rule, text inset 10 horizontal, 7 vertical; n = number of visual lines |
| Next row | `Y + 96 + 15*n`; add 17 per extra description line to code box origin and row advance |

Use read-only, selectable text; preserve literal body, case, spaces and hard newlines. Soft-wrap at word boundaries, prefer semicolons for long `/cast` clauses; wrapping never inserts a newline into the created/copied macro. No syntax colours. Proof first three rows: Charge / Intercept (3 visual lines), Overpower (2), Pummel (2). Then Shield Bash, Shield Wall, Bloodrage + Battle Shout, Mouseover Taunt, in Task 11 order after filtering. Names/descriptions from macro data; body from the same resolved source as Create, not a second UI copy. Shield macros without a shield display the template and `MACRO_NEEDS_SHIELD`; Create disabled. Unknown required spell: omit row. No eligible rows: `No macros available for the spells you know.` at `200,140,624,40`.

Tab through rows top-to-bottom: macro text (select/copy, never edit) → Create. Create adds one **character** macro `RB <name>`, never assigns a bar slot or replaces an existing macro. On success change button to disabled `Created` and append `Info: Added RB <name> to your character macros.` Already exists → `Exists` plus existing-name reason. Combat/full list → refuse creation, show `ERR_IN_COMBAT` / `ERR_MACROS_FULL`; missing entry → `ERR_NO_MACRO` and refresh list. Recheck eligibility at click, on bag/macro change and combat end; never queue a surprise creation. Slot for message `(208, codeBottom+4,608,H)`; push following rows down by H+4. For page-wide conditions show one banner at `200,140,624,H` and shift/shorten viewport by H+8 rather than repeat seven warnings.

## General

Use shared heading `SETTINGS / General`. Boxes in tab order; static help is not focusable. Settings affect current profile. Disabling tracking never locks this page or its recovery actions.

| Region | Placement |
|---|---|
| Tracking | Heading `200,110,640,18`; Enable Rageborn `200,138,300,26`; Global alert scale `200,180,300,32`, 50–200%, step 5%, default 100%. Explicitly **not** window scale. |
| Macro buttons | Heading `200,235,640,18`; Glow for every spell in a macro `200,261,500,26`; help `200,293,630,34`: “Off: match the spell the button shows. On: also match spells named in the macro.” |
| Placement & testing | Heading `200,344,640,18`; Move mode / Finish moving `200,374,128,26`; Test all `336,374,84,26`; help `200,408,630,34`: “Drag the labelled alerts, then finish moving. Screen-edge alerts stay fixed.” |
| Recovery | Status `200,459,640,32`; separator `200,499,640,1`; Reset everything `200,511,140,26`. Confirm: “Reset all Rageborn settings in ‘<current>’, including window and alert positions? Other profiles and game macros are unchanged.” Call current-profile reset, not account deletion. |

Test all uses eligible alerts. If none, disable and explain `No alerts available to test.` Move unavailable in combat or without enabled movable alerts; state the reason in help. Global changes reapply affected alerts/refresh; macro matching also refreshes bar matches. Do not touch protected bars from settings.

## Profiles

Shared `LIBRARY / Profiles`. Make the active profile and the *management target* separate: deleting the current profile is forbidden by the DB, so a switching dropdown alone cannot serve as the Delete target. Account-wide named profiles; character chooses its active one. Never switch as a side effect of merely selecting a management target.

| Region | Placement and tab order |
|---|---|
| Current | Heading `200,110,640,18`; Current profile label `200,141,134,18`; switch dropdown `344,136,292,26`; help `200,171,630,34`: “This character uses the selected profile.” |
| Manage | Heading `200,219,640,18`; Profile to manage label `200,250,140,18`; dropdown `344,245,292,26`, initially current. Name label `200,293,134,18`; input `344,288,292,26`, placeholder “New profile name”. |
| Operations | New `200,338,72,26`; Copy from `280,338,100,26`; Rename `388,338,86,26`; Delete `482,338,74,26`. Help `200,379,630,44`: “New and Copy from create a profile with the name above. Rename and Delete affect the profile to manage.” |
| Status / reset | Message `200,445,640,46`; separator `200,499,640,1`; Reset current profile `200,511,158,26`. |

New = `Create(input)` using defaults; Copy from = `Create(input, target)` (new copy, **no overwrite**). Select new name in management dropdown but do not activate. Rename = `Rename(target,input)`; on success update both dropdowns as appropriate. Delete confirms the named non-current target and warns characters using it revert to their own profile at next login; after delete target current. Reset confirms and calls `Reset()` on current only. Sorted names, no import/export. Blank/taken/missing/current-in-use → localized `errKey` in status, preserve input and focus offending control. Guard all mutations at click; refuse profile switches in combat with `ERR_IN_COMBAT`, keep current selection, never queue. Also block resets or renames that affect active settings in combat; no silent write. If list is empty after init, show `No profiles available.` and a New action rather than an invalid dropdown selection. Failed operation never displays success.

**Confirmation dialog:** centred `238,197,384,166` at rest, opaque Cap/Rule, local modal mouse/key capture. Title `254,211,352,22`, wrapping prompt `254,242,352,65`, Cancel `434,322,76,26`, explicit Reset/Delete `518,322,88,26`. Focus Cancel first; Tab cycles two buttons; Escape cancels. Grow vertically by 17 per extra line, centre again; apply only on explicit destructive activation. Restore focus to caller.

## Scale, overflow and acceptance

Inherit `UIParent` scale, **not** global alert scale. The layout always measures 860×560 logical units. At physical pixels per logical unit `s=0.64`, it occupies approximately 550×358 physical pixels; at 0.8, 688×448; at 1.0, 860×560. Use actual parent effective scale × device mapping for `s`, not just the slider value. Snap each shared edge with `round(coord*s)/s`; derive width from snapped endpoints. Hairlines use `1/s` logical units (one physical pixel); never independently round adjacent widths. All hit regions follow their snapped frames, not texture bounds. Raster proofs are 2× design-space exports, not a request for 2 px in-game borders.

Keep 13/15/18 text sizes in UI units; minimum small caption/preview text is 10. Do not rescale the tree a second time or lay out text in physical pixels. At either scale, retain 4 gallery columns and the full control hit zones. On a viewport smaller than the logical window, apply only the uniform fit factor `min(1, availableWidth/860, availableHeight/560)` and re-clamp; never crop the title/close. This emergency fit sacrifices legibility, not access. Long localized labels use full tooltip/focus text; descriptions and errors wrap. If action-page content overflows vertically, keep header and footer pinned, clip the middle (`200,208,640,285` for Alert, `200,106,640,387` for General/Profiles), provide a rail at x846 and scroll focused fields into view. Increase content height by actual wrapped-line increments rather than overlaying controls.

**In-client sign-off:** compare the three proof states at 1.0 and 0.64; inspect focus and ticks on light and black swatches, four uncut tile columns, macro selection/copy, and no art escaping a scrolled preview. Test unknown spells, unreadable probes, no shield, full macro list, combat switch refusal, duplicate/blank profile names and cancel on both destructive actions. Drag window to an edge, reopen on another scale, and confirm close remains reachable. These are acceptance checks, not claims of in-game verification.
