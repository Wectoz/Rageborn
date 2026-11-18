local made = {}
CreateFrame = function() local w = Stub.widget(); made[#made + 1] = w; return w end
UIParent, GameFontNormal = Stub.widget(), Stub.widget()
UIParent.GetWidth = function() return 1000 end
UIParent.GetHeight = function() return 800 end

local ns = Stub.load("Util.lua", {})
for _, f in ipairs({"Locale.lua", "Data.lua", "Database.lua", "ArtList.lua", "PaintedList.lua", "Styles.lua",
                    "Sounds.lua", "Engine.lua", "Alerts.lua", "Mover.lua"}) do Stub.load(f, ns) end
ns.Say = function() end
local M, DB, E = ns.Mover, ns.DB, ns.Engine
local function handles()
  local t = {}
  for _, w in ipairs(made) do if w.key then t[w.key] = w end end
  return t
end
local function reset() M:Toggle(false); RagebornDB = nil; DB:Init("Bob-Realm"); E:Reset() end

return {
{"move mode shows a handle for enabled, placeable alerts only, and test mode with it", function()
  reset(); DB:Alert("revenge").enabled = false; DB:Alert("lowHealth").style = "vignette"
  M:Toggle(true); local h = handles()
  assert(M:IsOn() and E:IsTesting())
  assert(h.overpower.shown == true and h.revenge.shown == false and h.lowHealth.shown == false)
  M:Toggle(false); assert(not M:IsOn() and not E:IsTesting() and h.overpower.shown == false) end},
{"move mode leaves test mode on when the player had it on", function()
  reset(); E:Test(true); M:Toggle(true); M:Toggle(false); assert(E:IsTesting()) end},
{"handles of alerts at one position are stacked, and dropping saves the alert's own position", function()
  reset(); M:Toggle(true); local h = handles()
  assert(h.overpower.dy == 0 and h.execute.dy > 0)       -- both start at the screen centre
  h.execute.GetCenter = function() return 700, 300 - h.execute.dy end
  h.execute.scripts.OnDragStart(h.execute); h.execute.scripts.OnDragStop(h.execute)
  local o = DB:Alert("execute"); assert(o.x == 200 and o.y == -100, o.x .. " " .. o.y)
  assert(h.execute.dy == 0)                              -- alone at its new place
  M:ResetPosition("execute"); assert(o.x == 0 and o.y == 0) end},
{"entering combat ends move mode", function()
  reset(); M:Toggle(true)
  for _, w in ipairs(made) do if w.calls.RegisterEvent then w.scripts.OnEvent() end end
  assert(not M:IsOn()) end},
}
