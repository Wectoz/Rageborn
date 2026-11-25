-- The minimap button: the angle <-> position maths, and that it follows the profile.
local made = {}
CreateFrame = function() local w = Stub.widget(); made[#made + 1] = w; return w end
Minimap, GameTooltip = Stub.widget(), Stub.widget()
Minimap.GetWidth = function() return 140 end
Minimap.GetCenter = function() return 900, 700 end
Minimap.GetEffectiveScale = function() return 0.5 end
local cursor = { 0, 0 }
GetCursorPosition = function() return cursor[1], cursor[2] end

local ns = Stub.load("Util.lua", {})
for _, f in ipairs({"Locale.lua", "Data.lua", "Database.lua", "Minimap.lua"}) do Stub.load(f, ns) end
local M, DB = ns.Minimap, ns.DB
local tested, toggled = nil, 0
ns.Engine = { Test = function(_, on) tested = on end }
ns.Options = { Toggle = function() toggled = toggled + 1 end }
local function near(a, b) return math.abs(a - b) < 0.001 end
RagebornDB = nil; DB:Init("Bob-Realm"); M:Start(); M:Start()
local b = made[1]

return {
{"an angle is a place on the edge, and a place gives its angle back", function()
  local x, y = M.Position(0, 75); assert(near(x, 75) and near(y, 0))
  x, y = M.Position(90, 75); assert(near(x, 0) and near(y, 75))
  x, y = M.Position(225, 100); assert(near(x, -70.7107) and near(y, -70.7107))
  assert(near(M.Angle(1, 0), 0) and near(M.Angle(0, 2), 90) and near(M.Angle(-3, 0), 180) and near(M.Angle(0, -1), 270))
  for _, a in ipairs({ 0, 33, 200, 359 }) do assert(near(M.Angle(M.Position(a, 75)), a), a) end end},
{"one button, placed at the saved angle just outside the minimap", function()
  assert(#made == 1 and b.shown == true)
  local p = b.calls.SetPoint; local x, y = M.Position(200, 75)
  assert(p[1] == "CENTER" and p[2] == Minimap and near(p[4], x) and near(p[5], y)) end},
{"hide and show follow the setting and the profile", function()
  local opt = DB:Profile().minimap; assert(opt.hide == false and opt.angle == 200)
  opt.hide = true; M:Apply(); assert(b.shown == false)
  DB:Create("Other"); DB:Use("Other"); assert(b.shown == true)       -- a new profile shows it again
  DB:Profile().minimap.angle = 90; DB:Use("Bob-Realm"); assert(b.shown == false)
  DB:Reset(); assert(b.shown == true and near(b.calls.SetPoint[4], (M.Position(200, 75)))) end},
{"dragging saves the angle towards the mouse, whatever the interface scale", function()
  cursor = { 450, 400 }                         -- (900, 800) in the minimap's own scale: straight above
  b.scripts.OnDragStart(b); b.scripts.OnUpdate(b); b.scripts.OnDragStop(b)
  assert(near(DB:Profile().minimap.angle, 90) and near(b.calls.SetPoint[5], 75) and b.scripts.OnUpdate == nil)
  GetCursorPosition = function() return Stub.secret(), 1 end     -- unreadable: stays where it is
  b.scripts.OnDragStart(b); b.scripts.OnUpdate(b); b.scripts.OnDragStop(b)
  assert(near(DB:Profile().minimap.angle, 90)) end},
{"left click toggles the settings, right click test mode; the tooltip opens", function()
  b.scripts.OnClick(b, "LeftButton"); assert(toggled == 1 and tested == nil)
  b.scripts.OnClick(b, "RightButton"); assert(tested == true and ns.testing == true)
  b.scripts.OnClick(b, "RightButton"); assert(tested == false and toggled == 1)
  b.scripts.OnEnter(b); assert(GameTooltip.calls.AddLine[1] == ns.L.MINIMAP_DRAG); b.scripts.OnLeave(b) end},
}
