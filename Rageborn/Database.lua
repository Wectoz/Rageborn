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
    local p = { enabled = true, scale = 1, sounds = true, critSound = "none", glowEveryMacroSpell = false, window = { x = 0, y = 0, scale = 1, headFont = "friz", textFont = "arial" }, minimap = { angle = 200, hide = false }, alerts = {} }
    local count, index = {}, {}
    for _, def in ipairs(Data.ALERTS) do count[def.group] = (count[def.group] or 0) + 1 end
    for _, def in ipairs(Data.ALERTS) do
        index[def.group] = (index[def.group] or 0) + 1
        p.alerts[def.key] = alertDefaults(def, index[def.group], count[def.group])
    end
    return p
end
DB.Defaults = profileDefaults

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

function DB:Create(name, copyFrom)
    name = trim(name)
    if not name then return false, "ERR_NAME_EMPTY" end
    local profiles = RagebornDB.profiles
    if profiles[name] ~= nil then return false, "ERR_NAME_TAKEN" end
    if copyFrom ~= nil and profiles[copyFrom] == nil then return false, "ERR_NO_PROFILE" end
    profiles[name] = copyFrom and U.DeepCopy(profiles[copyFrom]) or {}
    repair(name)
    changed()
    return true
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
    changed()
    return true
end

function DB:Reset()
    RagebornDB.profiles[current] = profileDefaults()
    changed()
end

function DB:OnChange(fn) listeners[#listeners + 1] = fn end
