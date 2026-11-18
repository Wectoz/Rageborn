-- Smoke test of Glow against fake buttons, a fake Bars and a widget that accepts any call.
local made = {}
CreateFrame = function(_, _, parent) local w = Stub.widget(); w.parent = parent; made[#made + 1] = w; return w end
local inCombat, atlases = false, true
InCombatLockdown = function() return inCombat end
C_Texture = { GetAtlasInfo = function() return atlases and {} or nil end }

local ns = Stub.load("Util.lua", {})
for _, f in ipairs({"Locale.lua", "Data.lua", "Database.lua"}) do Stub.load(f, ns) end
local alert, rescan, on = nil, nil, {}        -- on: spell ID -> the buttons that cast it
ns.Engine = { Subscribe = function(_, fn) alert = fn end }
ns.Bars = { OnRescan = function(_, fn) rescan = fn end, ButtonsFor = function(_, id) return on[id] or {} end }
Stub.load("Glow.lua", ns)
local G, DB = ns.Glow, ns.DB
RagebornDB = nil; DB:Init("Bob-Realm")
local function button(protected) local b = Stub.widget(); b.IsProtected = function() return protected end; return b end
local function glowOf(b) for _, w in ipairs(made) do if w.parent == b then return w end end end
local function lit(b) local f = glowOf(b); return f ~= nil and f.shown == true end
local function regen() for _, w in ipairs(made) do if w.calls.RegisterEvent then w.scripts.OnEvent() end end end
local a, b, c = button(true), button(true), button(false)
on[11585], on[6572] = { a, b }, { b }
G:Start()

return {
{"four styles; each draws, an unknown one too, and a missing atlas falls back", function()
  assert(table.concat(G.STYLES, " ") == "procLoop ants pulse corners")
  local x = button(false)
  for _, style in ipairs({ "procLoop", "ants", "pulse", "corners", "gone" }) do G:Show(x, style, 1, 0.5, 0) end
  atlases = false; G:Show(button(false), "ants", 1, 1, 1); atlases = true
  assert(lit(x)); G:Hide(x); assert(not lit(x)); G:Hide(button(false)) end},
{"the glow frame is the button's child, five levels up, sized from the button", function()
  local x = button(false); x.GetFrameLevel = function() return 3 end; x.GetWidth = function() return 40 end
  x.GetHeight = function() return Stub.secret() end       -- a size we can't read: the usual 36
  G:Show(x, "procLoop", 1, 1, 1); local f = glowOf(x)
  assert(f.calls.SetFrameLevel[1] == 8 and f.calls.SetPoint[2] == x)
  assert(math.abs(f.calls.SetSize[1] - 56) < 0.01 and math.abs(f.calls.SetSize[2] - 50.4) < 0.01) end},
{"frames are made ahead for every button an alert could light", function()
  assert(glowOf(a) and glowOf(b) and not lit(a)) end},
{"an alert lights its buttons and puts them out; a second alert keeps a shared button lit", function()
  alert("overpower", true, { spellID = 11585 }); assert(lit(a) and lit(b))
  alert("revenge", true, { spellID = 6572 })
  alert("overpower", false); assert(not lit(a) and lit(b))
  alert("revenge", false); assert(not lit(b)) end},
{"glow off for the alert: nothing lights; turned on again by a refresh", function()
  DB:Alert("overpower").glow = false
  alert("overpower", true, { spellID = 11585 }); assert(not lit(a))
  DB:Alert("overpower").glow = true
  alert("overpower", true, { spellID = 11585 }); assert(lit(a))
  alert("overpower", false) end},
{"a rescan moves the glow to where the spell is now", function()
  alert("overpower", true, { spellID = 11585 }); assert(lit(a))
  on[11585] = { b }; rescan(); assert(not lit(a) and lit(b))
  on[11585] = { a, b }; alert("overpower", false) end},
{"in combat a new protected button waits for the end of the fight; an unprotected one glows at once", function()
  local p = button(true); on[11585] = { p, c }
  inCombat = true; alert("overpower", true, { spellID = 11585 })
  assert(lit(c) and glowOf(p) == nil)
  inCombat = false; regen(); assert(lit(p))
  alert("overpower", false); assert(not lit(p) and not lit(c)); on[11585] = { a, b } end},
{"an alert with no spell, an unknown alert and a missing info are harmless", function()
  alert("lowHealth", true, {}); alert("gone", true, { spellID = 1 }); alert("overpower", true); alert("overpower", false) end},
}
