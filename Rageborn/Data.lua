local ADDON, ns = ...

-- Rageborn: the alerts it knows, as data. The engine reads these fields, so a new alert is
-- a new entry here plus its texts in Locale.lua.
--
--   key      unique id, also the settings key
--   kind     "usable"    the ability can be pressed
--            "reminder"  a buff is missing or about to end
--            "active"    the player pressed it; shown until its duration ends
--            "lowHealth" health under the threshold with a defensive ready
--            "debuff"    an effect on the target (only where the client lets us read it)
--   group    where it is listed in the settings
--   spells   every rank, lowest first (the highest one the character knows is used)
--   proc     what opens it besides "usable": "targetDodge" | "avoided" (you dodged, parried
--            or blocked) | "kill" | "targetCasting" | "queued" (on next swing)
--   window   seconds a proc stays open
--   stances  where it can be pressed (1 battle, 2 defensive, 3 berserker); nil = any
--   duration seconds an "active" lasts / Battle Shout lasts (estimate until read from the buff)
--   ready    shown only while it is off cooldown
--   needs    spell -> what must be wrong with you for it to be worth pressing
--            (Detect.Afflictions: STUN, ROOT, SNARE, FEAR, CHARM, POISON, DISEASE ...)
--   enemies  shown only in a fight with at least `threshold` enemies (counted from nameplates)
--   recast   seconds it stays hidden after you cast it (its effect is then on the enemies)
--   defaultOpacity  0 = nothing on screen, button glow only
--   probe    the docs/probe-results.md line a "debuff" alert depends on
--
-- IDs and durations are Classic values, to be confirmed on Forever (docs/probe-results.md).
local Data = {}
ns.Data = Data

Data.STANCE = { battle = 1, defensive = 2, berserker = 3 }
Data.GROUPS = { "procs", "reminders", "defensives", "offensives", "lowHealth", "target" }

local DEFAULT_STYLE = {
    procs = "gameArt", reminders = "frame", defensives = "ring", offensives = "ring",
    lowHealth = "vignette", target = "bar",
}

local HEROIC_STRIKE = { 78, 284, 285, 1608, 11564, 11565, 11566, 11567, 25286 }
local CLEAVE = { 845, 7369, 11608, 11609, 20569 }
local function join(a, b)
    local t = {}
    for _, v in ipairs(a) do t[#t + 1] = v end
    for _, v in ipairs(b) do t[#t + 1] = v end
    return t
end

Data.ALERTS = {
    -- Procs
    { key = "overpower", kind = "usable", group = "procs", defaultOn = true,
      spells = { 7384, 7887, 11584, 11585 }, proc = "targetDodge", window = 5, stances = { 1 },
      procBuff = 1289682 },  -- Bloodthrill (Forever): a Rend tick opens Overpower for 5 s
    { key = "revenge", kind = "usable", group = "procs", defaultOn = true,
      spells = { 6572, 6574, 7379, 11600, 11601, 25288 }, proc = "avoided", window = 5, stances = { 2 } },
    { key = "execute", kind = "usable", group = "procs", defaultOn = true,
      spells = { 5308, 20658, 20660, 20661, 20662 }, stances = { 1, 3 } },
    { key = "victoryRush", kind = "usable", group = "procs", defaultOn = true,
      spells = { 402927 }, proc = "kill", window = 20 },
    { key = "interrupt", kind = "usable", group = "procs", defaultOn = true, defaultStyle = "arcs",
      spells = { 6552, 6554, 72, 1671, 1672 }, proc = "targetCasting" },  -- Pummel, Shield Bash

    -- Reminders
    { key = "shieldBlock", kind = "usable", group = "reminders", defaultOn = false,
      spells = { 2565 }, stances = { 2 }, needsShield = true, combatOnly = true },
    { key = "battleShout", kind = "reminder", group = "reminders", defaultOn = true,
      spells = { 6673, 5242, 6192, 11549, 11550, 11551, 25289 }, duration = 120, defaultThreshold = 3 },
    { key = "queued", kind = "active", group = "reminders", defaultOn = false,
      spells = join(HEROIC_STRIKE, CLEAVE), proc = "queued" },
    -- Demoralizing Shout when several enemies are in the fight
    { key = "demoPull", kind = "usable", group = "reminders", defaultOn = true,
      spells = { 1160, 6190, 11554, 11555, 11556 }, enemies = true, ready = true, recast = 30, defaultThreshold = 2 },

    -- Defensives
    { key = "shieldWall", kind = "active", group = "defensives", defaultOn = true, spells = { 871 }, duration = 10 },
    { key = "lastStand", kind = "active", group = "defensives", defaultOn = true, spells = { 12975 }, duration = 20 },
    { key = "shieldBlockUp", kind = "active", group = "defensives", defaultOn = false, spells = { 2565 }, duration = 5 },
    { key = "retaliation", kind = "active", group = "defensives", defaultOn = false, spells = { 20230 }, duration = 15 },

    -- Offensives
    { key = "recklessness", kind = "active", group = "offensives", defaultOn = true, spells = { 1719 }, duration = 15 },
    { key = "deathWish", kind = "active", group = "offensives", defaultOn = true, spells = { 12328 }, duration = 30 },
    { key = "sweepingStrikes", kind = "active", group = "offensives", defaultOn = false, spells = { 12292 }, duration = 20 },
    { key = "berserkerRage", kind = "active", group = "offensives", defaultOn = false, spells = { 18499 }, duration = 10 },
    { key = "bloodrage", kind = "active", group = "offensives", defaultOn = false, spells = { 2687 }, duration = 10 },
    -- The race's escape, when it would help: human (stunned), gnome (rooted or slowed),
    -- undead (feared or charmed), dwarf (poisoned or diseased). Button glow only.
    { key = "racial", kind = "usable", group = "defensives", defaultOn = true, ready = true,
      spells = { 59752, 20589, 7744, 20594 }, defaultOpacity = 0,
      needs = { [59752] = { "STUN" }, [20589] = { "ROOT", "SNARE" }, [7744] = { "FEAR", "CHARM" },
                [20594] = { "POISON", "DISEASE" } } },

    -- Low health: warns while one of these defensives is ready
    { key = "lowHealth", kind = "lowHealth", group = "lowHealth", defaultOn = true,
      defaultThreshold = 35, defensives = { "shieldWall", "lastStand" } },

    -- On the target
    { key = "sunder", kind = "debuff", group = "target", defaultOn = false,
      spells = { 7386, 7405, 8380, 11596, 11597 }, probe = "Target debuff" },
    { key = "rend", kind = "debuff", group = "target", defaultOn = false,
      spells = { 772, 6546, 6547, 6548, 11572, 11573, 11574 }, probe = "Target debuff" },
    { key = "demoShout", kind = "debuff", group = "target", defaultOn = false,
      spells = { 1160, 6190, 11554, 11555, 11556 }, probe = "Target debuff" },
    { key = "thunderClap", kind = "debuff", group = "target", defaultOn = false,
      spells = { 6343, 8198, 8204, 8205, 11580, 11581 }, probe = "Target debuff" },
}

Data.BY_KEY = {}
for _, def in ipairs(Data.ALERTS) do
    def.defaultStyle = def.defaultStyle or DEFAULT_STYLE[def.group]
    Data.BY_KEY[def.key] = def
end

-- The highest rank of the alert's spell the character knows, or nil.
function Data.Known(def, isKnown)
    local spells = def.spells
    if not spells then return nil end
    for i = #spells, 1, -1 do
        if ns.U.Clean(isKnown(spells[i])) == true then return spells[i] end
    end
    return nil
end
