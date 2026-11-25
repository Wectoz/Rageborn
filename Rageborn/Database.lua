local ADDON, ns = ...

-- Rageborn: saved settings. Profiles are saved per account; each character points at one
-- (its own by default). What is saved is always merged over the defaults, so a setting
-- added in a later version appears without wiping what the player chose.
local U, Data = ns.U, ns.Data

local DB = {}
ns.DB = DB

local listeners = {}
local current      -- name of the profile in use
local charKey      -- "Name-Realm"
local watcher, waiting   -- the frame that hears talent changes; a switch waiting for combat to end

local GROUP_Y = { procs = 0, reminders = -140, defensives = -200, offensives = -260, lowHealth = 0, target = -320 }
local COLOR = { gameArt = { 1, 1, 1 }, vignette = { 1, 0.1, 0.1 } }

local function alertDefaults(def, index, count)
    local style = ns.Styles and ns.Styles.DefaultFor(def) or def.defaultStyle
    local painted = style ~= def.defaultStyle
    -- painted art keeps its own colours (white tint); art sits around the character
    local c = painted and { 1, 1, 1 } or COLOR[def.defaultStyle] or { 1, 0.82, 0.2 }
    -- art overlays sit around the screen centre; the others line up in a row per group
    local centred = painted or def.defaultStyle == "gameArt" or def.defaultStyle == "vignette"
    local x = centred and 0 or (index - (count + 1) / 2) * 70
    return {
        enabled = def.defaultOn, style = style,
        color = { r = c[1], g = c[2], b = c[3] }, size = 1, opacity = 1,
        onScreen = def.defaultOpacity ~= 0,   -- false: sound and button glow only
        x = x, y = centred and 0 or GROUP_Y[def.group] or 0, spread = 1,
        side = "both", recolor = false,   -- two-sided art: which side; painted art: tint it
        showIcon = not painted, showName = false, showTimer = true,
        sound = "none", combatOnly = def.combatOnly or false,
        glow = true, glowStyle = "procLoop", glowColor = { r = 1, g = 0.85, b = 0.3 },
        stanceHint = true, threshold = def.defaultThreshold or 0,
    }
end

local function profileDefaults()
    local p = { enabled = true, scale = 1, sounds = false, critSound = "none", glowEveryMacroSpell = false, window = { x = 0, y = 0, scale = 1, headFont = "friz", textFont = "arial" }, minimap = { angle = 200, hide = false }, alerts = {} }
    local count, index = {}, {}
    for _, def in ipairs(Data.ALERTS) do count[def.group] = (count[def.group] or 0) + 1 end
    for _, def in ipairs(Data.ALERTS) do
        index[def.group] = (index[def.group] or 0) + 1
        p.alerts[def.key] = alertDefaults(def, index[def.group], count[def.group])
    end
    return p
end
DB.Defaults = profileDefaults

-- Presets: which alerts are on. Everything else stays as the player has it (ApplyPreset) or
-- at the defaults (Create). "standard" is each alert's own default; "empty" is nothing.
-- A key this version has no alert for is skipped; an alert not named here is off.
local function set(...)
    local s = { battleShout = true, interrupt = true, victoryRush = true, racial = true, fearBreak = true, lowHealth = true }
    for _, key in ipairs({ ... }) do s[key] = true end
    return s
end
DB.PRESETS = { "standard", "arms", "fury", "prot", "empty" }
DB.PRESET_ALERTS = {
    arms = set("overpower", "execute", "rend", "sweepingStrikes", "recklessness", "retaliation"),
    fury = set("execute", "deathWish", "recklessness", "berserkerRage", "bloodrage", "rageDump", "queued"),
    prot = set("revenge", "shieldBlock", "shieldBlockUp", "sunder", "taunt", "thunderClap", "demoPull",
               "shieldWall", "lastStand"),
    empty = {},
}

local function isPreset(key) return key == "standard" or DB.PRESET_ALERTS[key] ~= nil end

local function applyPreset(profile, key)
    local on = DB.PRESET_ALERTS[key]
    for _, def in ipairs(Data.ALERTS) do
        local alert = profile.alerts[def.key]
        if on then alert.enabled = on[def.key] == true else alert.enabled = def.defaultOn and true or false end
    end
end

local function trim(name)
    if type(name) ~= "string" then return nil end
    name = name:match("^%s*(.-)%s*$")
    return name ~= "" and name or nil
end

local function changed()
    for _, fn in ipairs(listeners) do fn() end
end

-- A profile that can be used: a table, with everything the defaults have.
local function repair(name)
    local db = RagebornDB
    if type(db.profiles[name]) ~= "table" then db.profiles[name] = {} end
    U.DeepMerge(db.profiles[name], profileDefaults())
end

function DB:Init(key)
    charKey = key
    if type(RagebornDB) ~= "table" then RagebornDB = {} end
    local db = RagebornDB
    db.version = 1
    if type(db.profiles) ~= "table" then db.profiles = {} end
    if type(db.chars) ~= "table" then db.chars = {} end
    local name = db.chars[key]
    if type(name) ~= "string" or db.profiles[name] == nil then name = key end
    db.chars[key] = name
    current = name
    repair(name)
    -- which profile each talent tree uses, per character
    if type(db.specs) ~= "table" then db.specs = {} end
    if type(db.specs[key]) ~= "table" then db.specs[key] = {} end
    if not watcher and CreateFrame then
        watcher = CreateFrame("Frame")
        for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_TALENT_UPDATE", "CHARACTER_POINTS_CHANGED",
                                 "ACTIVE_TALENT_GROUP_CHANGED", "TRAIT_CONFIG_UPDATED", "PLAYER_REGEN_ENABLED" }) do
            pcall(watcher.RegisterEvent, watcher, event)      -- not every client has every event
        end
        watcher:SetScript("OnEvent", function(_, event)
            if event ~= "PLAYER_REGEN_ENABLED" or waiting then DB:SpecSwitch() end
        end)
    end
end

function DB:Current() return current end
function DB:Profile() return RagebornDB.profiles[current] end

-- The settings of one alert, or nil for a key this version doesn't have.
function DB:Alert(key)
    if not Data.BY_KEY[key] then return nil end
    return RagebornDB.profiles[current].alerts[key]
end

function DB:List()
    local names = {}
    for name in pairs(RagebornDB.profiles) do names[#names + 1] = name end
    table.sort(names)
    return names
end

function DB:Use(name)
    if RagebornDB.profiles[name] == nil then return false, "ERR_NO_PROFILE" end
    current = name
    RagebornDB.chars[charKey] = name
    repair(name)
    changed()
    return true
end

-- A new profile: a copy of copyFrom, else the defaults with the preset's alerts switched on.
function DB:Create(name, copyFrom, preset)
    name = trim(name)
    if not name then return false, "ERR_NAME_EMPTY" end
    local profiles = RagebornDB.profiles
    if profiles[name] ~= nil then return false, "ERR_NAME_TAKEN" end
    if copyFrom ~= nil and profiles[copyFrom] == nil then return false, "ERR_NO_PROFILE" end
    if preset ~= nil and not isPreset(preset) then return false, "ERR_NO_PRESET" end
    profiles[name] = copyFrom and U.DeepCopy(profiles[copyFrom]) or {}
    repair(name)
    if preset and not copyFrom then applyPreset(profiles[name], preset) end
    changed()
    return true
end

-- Switches the current profile's alerts on and off as the preset says; nothing else changes.
function DB:ApplyPreset(key)
    if not isPreset(key) then return false, "ERR_NO_PRESET" end
    applyPreset(RagebornDB.profiles[current], key)
    changed()
    return true
end

-- Every character's talent choice that names `old` now names `new` (nil: nothing).
local function remap(old, new)
    for _, map in pairs(RagebornDB.specs or {}) do
        if type(map) == "table" then
            for spec, name in pairs(map) do if name == old then map[spec] = new end end
        end
    end
end

function DB:Rename(old, new)
    local profiles = RagebornDB.profiles
    if profiles[old] == nil then return false, "ERR_NO_PROFILE" end
    new = trim(new)
    if not new then return false, "ERR_NAME_EMPTY" end
    if profiles[new] ~= nil then return false, "ERR_NAME_TAKEN" end
    profiles[new], profiles[old] = profiles[old], nil
    for char, name in pairs(RagebornDB.chars) do
        if name == old then RagebornDB.chars[char] = new end
    end
    if current == old then current = new end
    remap(old, new)
    changed()
    return true
end

function DB:Delete(name)
    if RagebornDB.profiles[name] == nil then return false, "ERR_NO_PROFILE" end
    if name == current then return false, "ERR_PROFILE_IN_USE" end
    RagebornDB.profiles[name] = nil
    -- characters that used it fall back to their own profile at their next login (Init)
    for char, used in pairs(RagebornDB.chars) do
        if used == name then RagebornDB.chars[char] = nil end
    end
    remap(name, nil)
    changed()
    return true
end

function DB:Reset()
    RagebornDB.profiles[current] = profileDefaults()
    changed()
end

function DB:OnChange(fn) listeners[#listeners + 1] = fn end

----------------------------------------------------------------------
-- A profile per talent tree. spec = "arms" | "fury" | "prot" (Detect.Spec).
----------------------------------------------------------------------
-- The profile this character uses for the tree, or nil (none chosen, or it was deleted).
function DB:SpecProfile(spec)
    local name = RagebornDB.specs[charKey][spec]
    if type(name) == "string" and RagebornDB.profiles[name] ~= nil then return name end
    return nil
end

function DB:SetSpecProfile(spec, name)
    RagebornDB.specs[charKey][spec] = name
end

-- Switches to the profile chosen for the character's talents; in combat it waits for the
-- end of the fight. true when it switched.
function DB:SpecSwitch()
    local D = ns.Detect
    local spec = D and D.Spec()
    local name = spec and self:SpecProfile(spec)
    waiting = false
    if not name or name == current then return false end
    if D.InCombat() == true then waiting = true return false end
    self:Use(name)
    if ns.Say then ns.Say(ns.L.SPEC_SWITCHED:format(name)) end
    return true
end

----------------------------------------------------------------------
-- A profile as text: "RB1:" and the table written as (key=value,...), with 'text', numbers,
-- t and f. Printable ASCII only. Reading it never runs anything: the text is walked letter
-- by letter, and only what the defaults also have, with the same type, is kept.
----------------------------------------------------------------------
local MAX_IMPORT, MAX_DEPTH = 65536, 8
local RANGE = { size = { 0.5, 2 }, spread = { 0.5, 2 }, scale = { 0.5, 2 }, opacity = { 0, 1 }, threshold = { 0, 100 },
                r = { 0, 1 }, g = { 0, 1 }, b = { 0, 1 }, x = { -5000, 5000 }, y = { -5000, 5000 } }

local function pack(v)
    local t = type(v)
    if t == "boolean" then return v and "t" or "f" end
    if t == "number" then
        if v ~= v or v == math.huge or v == -math.huge then return nil end
        local s = ("%.14g"):format(v)
        return tonumber(s) == v and s or ("%.17g"):format(v)
    end
    if t == "string" then
        return "'" .. v:gsub("[^%w_:%.%-]", function(c) return ("%%%02X"):format(c:byte()) end) .. "'"
    end
    if t ~= "table" then return nil end
    local keys, parts = {}, {}
    for k in pairs(v) do
        if type(k) == "string" and k:find("^[%a_][%w_]*$") then keys[#keys + 1] = k end
    end
    table.sort(keys)
    for _, k in ipairs(keys) do
        local s = pack(v[k])
        if s then parts[#parts + 1] = k .. "=" .. s end
    end
    return "(" .. table.concat(parts, ",") .. ")"
end

-- The value that starts at s[i] and the place after it; nil when the text is malformed.
local function parse(s, i, depth)
    local c = s:sub(i, i)
    if c == "t" then return true, i + 1 end
    if c == "f" then return false, i + 1 end
    if c == "'" then
        local text, stop = s:match("^'([%w_:%.%-%%]*)'()", i)
        if not text or text:gsub("%%%x%x", ""):find("%%") then return nil end
        return text:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end), stop
    end
    if c ~= "(" then
        local digits, stop = s:match("^(%-?[%d%.]+[eE]?[%+%-]?%d*)()", i)
        local n = digits and tonumber(digits)
        if not n or n ~= n or n == math.huge or n == -math.huge then return nil end
        return n, stop
    end
    if depth > MAX_DEPTH then return nil end
    local t = {}
    i = i + 1
    if s:sub(i, i) == ")" then return t, i + 1 end
    while true do
        local key, at = s:match("^([%a_][%w_]*)=()", i)
        if not key then return nil end
        local v
        v, i = parse(s, at, depth + 1)
        if v == nil then return nil end
        t[key] = v
        c = s:sub(i, i)
        i = i + 1
        if c == ")" then return t, i end
        if c ~= "," then return nil end
    end
end

-- What of src the defaults also have. A value of another type than its default: nil (refuse).
local function fit(src, defaults)
    local out = {}
    for k, d in pairs(defaults) do
        local v = src[k]
        if v ~= nil then
            if type(v) ~= type(d) then return nil end
            if type(d) == "table" then
                v = fit(v, d)
                if not v then return nil end
            elseif type(d) == "number" then
                local r = RANGE[k] or { -1e6, 1e6 }
                v = math.max(r[1], math.min(r[2], v))
            elseif type(d) == "string" and #v > 64 then
                return nil
            end
            out[k] = v
        end
    end
    return out
end

-- The profile as text. The settings window's place, size and fonts are not included.
function DB:Export(name)
    local profile = RagebornDB.profiles[name or current]
    if type(profile) ~= "table" then return nil, "ERR_NO_PROFILE" end
    local shared = {}
    for k, v in pairs(profile) do if k ~= "window" then shared[k] = v end end
    return "RB1:" .. pack(shared)
end

-- Creates a new profile from text made by Export. Never overwrites one.
function DB:Import(name, text)
    name = trim(name)
    if not name then return false, "ERR_NAME_EMPTY" end
    local profiles = RagebornDB.profiles
    if profiles[name] ~= nil then return false, "ERR_NAME_TAKEN" end
    if type(text) ~= "string" or #text > MAX_IMPORT then return false, "ERR_IMPORT" end
    text = text:gsub("%s+", "")
    local version, body = text:match("^RB(%d+):(.*)$")
    if not version then return false, "ERR_IMPORT" end
    if version ~= "1" then return false, "ERR_IMPORT_VERSION" end
    local t, stop = parse(body, 1, 1)
    if type(t) ~= "table" or stop ~= #body + 1 then return false, "ERR_IMPORT" end
    t.window = nil
    local profile = fit(t, profileDefaults())
    if not profile then return false, "ERR_IMPORT" end
    profiles[name] = profile
    repair(name)
    changed()
    return true
end
