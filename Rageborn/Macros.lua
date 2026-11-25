local ADDON, ns = ...

-- Rageborn: ready-made macros, as data. A new macro is a new entry in LIST plus its
-- description in Locale.lua (MACRO_<key>).
--
--   key       unique id
--   name      the macro is created as "RB <name>" (the game allows 16 characters)
--   body      the macro text; <shield> becomes the name of a shield the character carries
--             <charge> the stances Charge works in: 1, or 1/2 with the Vanguard talent
--   requires  SPELLS keys; the macro is offered when one rank of each is known
--   spec      the specs it is listed under ("arms", "fury", "prot"); none = every spec
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
    whirlwind = { 1680 },
    disarm = { 676 },
    intimidatingShout = { 5246 },
    overpower = Data.BY_KEY.overpower.spells,
    execute = Data.BY_KEY.execute.spells,
    revenge = Data.BY_KEY.revenge.spells,
    rend = Data.BY_KEY.rend.spells,
    recklessness = Data.BY_KEY.recklessness.spells,
    retaliation = Data.BY_KEY.retaliation.spells,
    sweepingStrikes = Data.BY_KEY.sweepingStrikes.spells,
    shieldWall = Data.BY_KEY.shieldWall.spells,
    bloodrage = Data.BY_KEY.bloodrage.spells,
    battleShout = Data.BY_KEY.battleShout.spells,
}

Macros.LIST = {
    { key = "chargeIntercept", name = "Charge",
      body = "#showtooltip\n/dismount\n/startattack\n/cast [stance:<charge>,nocombat] Charge; [stance:3] Intercept; [combat] Berserker Stance; Battle Stance",
      requires = { "charge", "intercept", "battleStance", "berserkerStance" } },
    { key = "overpowerAny", name = "Overpower",
      body = "#showtooltip Overpower\n/startattack\n/cast [nostance:1] Battle Stance; Overpower",
      requires = { "overpower", "battleStance" }, spec = { "arms", "fury" } },
    { key = "pummelAny", name = "Pummel",
      body = "#showtooltip Pummel\n/startattack\n/cast [nostance:3] Berserker Stance; Pummel",
      requires = { "pummel", "berserkerStance" } },
    { key = "shieldBash", name = "Shield Bash",
      body = "#showtooltip Shield Bash\n/startattack\n/equipslot [noworn:Shields] 17 <shield>\n/cast [stance:1/2] Shield Bash; Defensive Stance",
      requires = { "shieldBash", "defensiveStance" }, spec = { "prot" } },
    { key = "shieldWall", name = "Shield Wall",
      body = "#showtooltip Shield Wall\n/equipslot [noworn:Shields] 17 <shield>\n/cast [nostance:2] Defensive Stance; Shield Wall",
      requires = { "shieldWall", "defensiveStance" }, spec = { "prot" } },
    { key = "rageShout", name = "Rage Shout",
      body = "#showtooltip Battle Shout\n/cast Bloodrage\n/cast Battle Shout",
      requires = { "bloodrage", "battleShout" } },
    { key = "tauntMouseover", name = "Taunt",
      body = "#showtooltip Taunt\n/cast [nostance:2] Defensive Stance; [@mouseover,harm,nodead] Taunt; Taunt",
      requires = { "taunt", "defensiveStance" }, spec = { "prot" } },
    { key = "chargeMouseover", name = "Charge Mouse",
      body = "#showtooltip\n/dismount\n/startattack\n/cast [@mouseover,harm,nodead,stance:<charge>] Charge; [@mouseover,harm,nodead,stance:3] Intercept; [stance:<charge>] Charge; [stance:3] Intercept",
      requires = { "charge", "intercept" } },
    { key = "burst", name = "Death Wish",
      body = "#showtooltip Death Wish\n/cast Bloodrage\n/cast Death Wish",
      requires = { "bloodrage", "deathWish" }, spec = { "arms", "fury" } },
    { key = "berserkerRageAny", name = "Berserk Rage",
      body = "#showtooltip Berserker Rage\n/cast [nostance:3] Berserker Stance; Berserker Rage",
      requires = { "berserkerRage", "berserkerStance" } },
    { key = "mockingBlowAny", name = "Mocking Blow",
      body = "#showtooltip Mocking Blow\n/startattack\n/cast [nostance:1] Battle Stance; Mocking Blow",
      requires = { "mockingBlow", "battleStance" }, spec = { "prot" } },
    { key = "hamstringAny", name = "Hamstring",
      body = "#showtooltip Hamstring\n/startattack\n/cast [stance:2] Battle Stance; Hamstring",
      requires = { "hamstring", "battleStance" }, spec = { "arms", "fury" } },
    { key = "shieldBlock", name = "Shield Block",
      body = "#showtooltip Shield Block\n/equipslot [noworn:Shields] 17 <shield>\n/cast [nostance:2] Defensive Stance; Shield Block",
      requires = { "shieldBlock", "defensiveStance" }, spec = { "prot" } },
    -- From the owner's own set: one ability a button, attack started, the stance fixed first.
    { key = "executeAny", name = "Execute",
      body = "#showtooltip Execute\n/startattack\n/cast [stance:2] Battle Stance; Execute",
      requires = { "execute", "battleStance" }, spec = { "arms", "fury" } },
    { key = "whirlwindAny", name = "Whirlwind",
      body = "#showtooltip Whirlwind\n/startattack\n/cast [nostance:3] Berserker Stance; Whirlwind",
      requires = { "whirlwind", "berserkerStance" }, spec = { "arms", "fury" } },
    { key = "rendAny", name = "Rend",
      body = "#showtooltip Rend\n/startattack\n/cast [stance:3] Battle Stance; Rend",
      requires = { "rend", "battleStance" }, spec = { "arms", "prot" } },
    { key = "revengeAny", name = "Revenge",
      body = "#showtooltip Revenge\n/startattack\n/cast [nostance:2] Defensive Stance; Revenge",
      requires = { "revenge", "defensiveStance" }, spec = { "prot" } },
    { key = "disarmAny", name = "Disarm",
      body = "#showtooltip Disarm\n/startattack\n/cast [nostance:2] Defensive Stance; Disarm",
      requires = { "disarm", "defensiveStance" }, spec = { "prot" } },
    { key = "recklessnessAny", name = "Recklessness",
      body = "#showtooltip Recklessness\n/startattack\n/cast [nostance:3] Berserker Stance; Recklessness",
      requires = { "recklessness", "berserkerStance" }, spec = { "arms", "fury" } },
    { key = "retaliationAny", name = "Retaliation",
      body = "#showtooltip Retaliation\n/startattack\n/cast [nostance:1] Battle Stance; Retaliation",
      requires = { "retaliation", "battleStance" }, spec = { "arms" } },
    { key = "sweepingAny", name = "Sweeping",
      body = "#showtooltip Sweeping Strikes\n/startattack\n/cast [nostance:1] Battle Stance; Sweeping Strikes",
      requires = { "sweepingStrikes", "battleStance" }, spec = { "arms" } },
    { key = "fearShout", name = "Intim. Shout",
      body = "#showtooltip Intimidating Shout\n/stopattack\n/cast Intimidating Shout",
      requires = { "intimidatingShout" } },
}

Macros.BY_KEY = {}
for _, m in ipairs(Macros.LIST) do Macros.BY_KEY[m.key] = m end

function Macros.Name(m) return PREFIX .. m.name end

-- The macros whose spells the character knows, in LIST order; with a spec, only that spec's.
function Macros.Available(isKnown, spec)
    local list = {}
    for _, m in ipairs(Macros.LIST) do
        local all = true
        if spec and m.spec then
            all = false
            for _, s in ipairs(m.spec) do all = all or s == spec end
        end
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
        return equipLoc == "INVTYPE_SHIELD" and (U.Call(C_Item.GetItemNameByID, item) or (U.Call(GetItemInfo, item))) or nil
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
local VANGUARD = 1310317      -- Forever talent: Charge also works in Defensive Stance
function Macros.Body(m)
    local body = m.body:gsub("<charge>", ns.Detect.IsKnown(VANGUARD) and "1/2" or "1")
    if not body:find("<shield>", 1, true) then return body end
    local shield = shieldName()
    if not shield then return body, "MACRO_NEEDS_SHIELD" end
    return (body:gsub("<shield>", (shield:gsub("%%", "%%%%"))))
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
