-- The macro library: its data, and Create against a fake of the game's macro list.
local inCombat, unknown, mine, made, offHand, bags = false, nil, {}, nil, nil, {}
local ITEMS = { [10] = { "Worn Buckler", "INVTYPE_SHIELD" }, [11] = { "Rusty Sword", "INVTYPE_WEAPON" } }
InCombatLockdown = function() return inCombat end
IsPlayerSpell = function(id) return id ~= unknown end
GetNumMacros = function() return 3, #mine end
GetMacroInfo = function(i) return mine[i - 120] end
CreateMacro = function(...) made = { ... }; return 121 end
GetInventoryItemID = function() return offHand end
C_Item = { GetItemInfoInstant = function(id) return id, nil, nil, ITEMS[id][2] end,
           GetItemNameByID = function(id) return ITEMS[id][1] end }
C_Container = { GetContainerNumSlots = function(bag) return bags[bag] and #bags[bag] or 0 end,
                GetContainerItemID = function(bag, slot) return bags[bag][slot] or nil end }

local ns = Stub.load("Util.lua", {})
for _, f in ipairs({"Locale.lua", "Data.lua", "Detect.lua", "Bars.lua", "Macros.lua"}) do Stub.load(f, ns) end
local Macros, Bars, L = ns.Macros, ns.Bars, ns.L
local function fresh() inCombat, unknown, mine, made, offHand, bags = false, nil, {}, nil, nil, {} end
local function refused(key, err)
  local ok, got = Macros.Create(key)
  assert(ok == false and got == err, tostring(got)); assert(made == nil, "a macro was created")
end

return {
{"every body is at most 255 characters and every name fits the game's 16", function()
  for _, m in ipairs(Macros.LIST) do
    assert(#m.body + 40 <= 255, m.key)            -- 40: room for a long shield name
    assert(#("RB " .. m.name) <= 16, m.key)
  end end},
{"every body parses to at least one spell", function()
  for _, m in ipairs(Macros.LIST) do assert(#Bars.MacroSpells(m.body) > 0, m.key) end end},
{"every macro has a description, every required spell a list, every refusal a text", function()
  for _, m in ipairs(Macros.LIST) do
    assert(rawget(L, "MACRO_" .. m.key), m.key)
    for _, s in ipairs(m.requires) do assert(Macros.SPELLS[s], m.key .. " " .. s) end
  end
  for _, k in ipairs({"ERR_IN_COMBAT", "ERR_MACROS_FULL", "ERR_MACRO_EXISTS", "ERR_NO_MACRO", "MACRO_NEEDS_SHIELD"}) do
    assert(rawget(L, k), k)
  end end},
{"Available hides macros with an unknown spell", function()
  fresh(); assert(#Macros.Available(ns.Detect.IsKnown) == #Macros.LIST)
  unknown = 355                                   -- Taunt
  local list = Macros.Available(ns.Detect.IsKnown)
  assert(#list == #Macros.LIST - 1)
  for _, m in ipairs(list) do assert(m.key ~= "tauntMouseover") end end},
{"a lower rank is enough", function()
  fresh(); assert(#Macros.Available(function(id) return id == 6673 or id == 2687 end) == 1) end},
{"Create refuses in combat", function() fresh(); inCombat = true; refused("rageShout", "ERR_IN_COMBAT") end},
{"Create refuses when the character list is full", function()
  fresh(); for i = 1, 18 do mine[i] = "m" .. i end; refused("rageShout", "ERR_MACROS_FULL") end},
{"Create refuses a duplicate name", function()
  fresh(); mine = { "x", "RB Rage Shout" }; refused("rageShout", "ERR_MACRO_EXISTS") end},
{"Create refuses an unknown key", function() fresh(); refused("nope", "ERR_NO_MACRO"); refused(nil, "ERR_NO_MACRO") end},
{"Create refuses when the macro list can't be read", function()
  fresh(); local keep = GetNumMacros; GetNumMacros = nil; refused("rageShout", "ERR_NO_MACRO"); GetNumMacros = keep end},
{"Create calls CreateMacro with a per-character macro", function()
  fresh(); assert(Macros.Create("rageShout") == true)
  assert(made[1] == "RB Rage Shout" and made[3] == Macros.BY_KEY.rageShout.body and made[4] == true) end},
{"a shield macro needs a shield, and names the one in the bags or the off hand", function()
  fresh(); bags = { [0] = { 11 }, [2] = { false, 11 } }; refused("shieldBash", "MACRO_NEEDS_SHIELD")
  assert(Macros.Body(Macros.BY_KEY.shieldBash):find("<shield>", 1, true))     -- the template is still shown
  bags[2][3] = 10
  assert(Macros.Create("shieldWall") == true and made[3]:find("17 Worn Buckler\n", 1, true), made[3])
  assert(not made[3]:find("<", 1, true))
  bags = {}; offHand = 10
  assert(select(2, Macros.Body(Macros.BY_KEY.shieldBash)) == nil) end},
}
