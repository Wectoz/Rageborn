local ADDON, ns = ...

-- Rageborn: ready-made macros, as data. A new macro is a new entry in LIST plus its
-- description in Locale.lua (MACRO_<key>).
--
--   key       unique id
--   name      the macro is created as "RB <name>" (the game allows 16 characters)
--   body      the macro text; <shield> becomes the name of a shield the character carries
--   requires  SPELLS keys; the macro is offered when one rank of each is known
local U, Data = ns.U, ns.Data

local Macros = {}
ns.Macros = Macros

local ICON = "INV_Misc_QuestionMark"    -- the game then shows what #showtooltip names
local PREFIX = "RB "

-- Every rank, lowest first. Classic IDs, like Data.lua.
Macros.SPELLS = {
    charge = { 100, 6178, 11578 },
    intercept = { 20252, 20616, 20617 },
    battleStance = { 2457 },
    defensiveStance = { 71 },
    berserkerStance = { 2458 },
    pummel = { 6552, 6554 },
    shieldBash = { 72, 1671, 1672 },
    taunt = { 355 },
    deathWish = { 12328 },
    berserkerRage = { 18499 },
    mockingBlow = { 694, 7400, 7402, 20559, 20560 },
    hamstring = { 1715, 7372, 7373 },
    shieldBlock = { 2565 },
    overpower = Data.BY_KEY.overpower.spells,
    shieldWall = Data.BY_KEY.shieldWall.spells,
    bloodrage = Data.BY_KEY.bloodrage.spells,
    battleShout = Data.BY_KEY.battleShout.spells,
}

Macros.LIST = {
    { key = "chargeIntercept", name = "Charge",
      body = "#showtooltip\n/cast [stance:1,nocombat] Charge; [stance:3] Intercept; [combat] Berserker Stance; Battle Stance",
      requires = { "charge", "intercept", "battleStance", "berserkerStance" } },
    { key = "overpowerAny", name = "Overpower",
      body = "#showtooltip Overpower\n/cast [nostance:1] Battle Stance; Overpower",
      requires = { "overpower", "battleStance" } },
    { key = "pummelAny", name = "Pummel",
      body = "#showtooltip Pummel\n/cast [nostance:3] Berserker Stance; Pummel",
      requires = { "pummel", "berserkerStance" } },
    { key = "shieldBash", name = "Shield Bash",
      body = "#showtooltip Shield Bash\n/equipslot [noworn:Shields] 17 <shield>\n/cast [stance:1/2] Shield Bash; Defensive Stance",
      requires = { "shieldBash", "defensiveStance" } },
    { key = "shieldWall", name = "Shield Wall",
      body = "#showtooltip Shield Wall\n/equipslot [noworn:Shields] 17 <shield>\n/cast [nostance:2] Defensive Stance; Shield Wall",
      requires = { "shieldWall", "defensiveStance" } },
    { key = "rageShout", name = "Rage Shout",
      body = "#showtooltip Battle Shout\n/cast Bloodrage\n/cast Battle Shout",
      requires = { "bloodrage", "battleShout" } },
    { key = "tauntMouseover", name = "Taunt",
      body = "#showtooltip Taunt\n/cast [nostance:2] Defensive Stance; [@mouseover,harm,nodead] Taunt; Taunt",
      requires = { "taunt", "defensiveStance" } },
    { key = "chargeMouseover", name = "Charge Mouse",
      body = "#showtooltip\n/cast [@mouseover,harm,nodead,stance:1] Charge; [@mouseover,harm,nodead,stance:3] Intercept; [stance:1] Charge; [stance:3] Intercept",
      requires = { "charge", "intercept" } },
    { key = "burst", name = "Death Wish",
      body = "#showtooltip Death Wish\n/cast Bloodrage\n/cast Death Wish",
      requires = { "bloodrage", "deathWish" } },
    { key = "berserkerRageAny", name = "Berserk Rage",
      body = "#showtooltip Berserker Rage\n/cast [nostance:3] Berserker Stance; Berserker Rage",
      requires = { "berserkerRage", "berserkerStance" } },
    { key = "mockingBlowAny", name = "Mocking Blow",
      body = "#showtooltip Mocking Blow\n/cast [nostance:1] Battle Stance; Mocking Blow",
      requires = { "mockingBlow", "battleStance" } },
    { key = "hamstringAny", name = "Hamstring",
      body = "#showtooltip Hamstring\n/cast [stance:2] Battle Stance; Hamstring",
      requires = { "hamstring", "battleStance" } },
    { key = "shieldBlock", name = "Shield Block",
      body = "#showtooltip Shield Block\n/equipslot [noworn:Shields] 17 <shield>\n/cast [nostance:2] Defensive Stance; Shield Block",
      requires = { "shieldBlock", "defensiveStance" } },
}

Macros.BY_KEY = {}
for _, m in ipairs(Macros.LIST) do Macros.BY_KEY[m.key] = m end

function Macros.Name(m) return PREFIX .. m.name end

-- The macros whose spells the character knows, in LIST order.
function Macros.Available(isKnown)
    local list = {}
    for _, m in ipairs(Macros.LIST) do
        local all = true
        for _, key in ipairs(m.requires) do
            local any = false
            for _, id in ipairs(Macros.SPELLS[key]) do any = any or U.Clean(isKnown(id)) == true end
            all = all and any
        end
        if all then list[#list + 1] = m end
    end
    return list
end

-- The name of the first shield in the off hand or the bags, or nil.
local function shieldName()
    local function name(item)
        if not item then return nil end
        local _, _, _, equipLoc = U.Call(C_Item and C_Item.GetItemInfoInstant, item)
        return equipLoc == "INVTYPE_SHIELD" and U.Call(C_Item.GetItemNameByID, item) or nil
    end
    local found = name(U.Call(GetInventoryItemID, "player", 17))
    for bag = 0, 4 do
        for slot = 1, not found and U.Call(C_Container and C_Container.GetContainerNumSlots, bag) or 0 do
            found = found or name(U.Call(C_Container.GetContainerItemID, bag, slot))
        end
    end
    return found
end

-- The text Create writes, and why it can't be created yet ("MACRO_NEEDS_SHIELD") if so.
function Macros.Body(m)
    if not m.body:find("<shield>", 1, true) then return m.body end
    local shield = shieldName()
    if not shield then return m.body, "MACRO_NEEDS_SHIELD" end
    return (m.body:gsub("<shield>", (shield:gsub("%%", "%%%%"))))
end

-- Whether the character already has a macro with this one's name.
function Macros.Exists(m)
    local account = MAX_ACCOUNT_MACROS or 120       -- character macros are numbered after these
    local _, mine = U.Call(GetNumMacros)
    for i = account + 1, account + (tonumber(mine) or 0) do
        if U.Call(GetMacroInfo, i) == Macros.Name(m) then return true end
    end
    return false
end

-- Adds the macro to the character's own macros. Returns true, or false and the L key of the
-- reason. Never replaces a macro and never puts it on a bar.
function Macros.Create(key)
    local m = Macros.BY_KEY[key]
    if not m then return false, "ERR_NO_MACRO" end
    if ns.Detect.InCombat() then return false, "ERR_IN_COMBAT" end
    local body, why = Macros.Body(m)
    if why then return false, why end
    local _, mine = U.Call(GetNumMacros)
    if type(mine) ~= "number" then return false, "ERR_NO_MACRO" end
    if Macros.Exists(m) then return false, "ERR_MACRO_EXISTS" end
    if mine >= (MAX_CHARACTER_MACROS or 18) then return false, "ERR_MACROS_FULL" end
    if not U.Call(CreateMacro, Macros.Name(m), ICON, body, true) then return false, "ERR_NO_MACRO" end
    return true
end
