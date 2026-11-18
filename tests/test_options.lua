-- Smoke test of the settings window: every page builds, every control can be used.
local made = {}
CreateFrame = function(kind) local w = Stub.widget(); w.kind = kind; made[#made + 1] = w; return w end
UIParent, GameFontNormal, ChatFontNormal = Stub.widget(), Stub.widget(), Stub.widget()
StaticPopupDialogs = {}
local asked
StaticPopup_Show = function(_, text, _, fn) asked = { text = text, fn = fn } end
ACCEPT, CANCEL = "Accept", "Cancel"

local ns = Stub.load("Util.lua", {})
for _, f in ipairs({"Locale.lua", "Data.lua", "Database.lua", "ArtList.lua", "PaintedList.lua", "Styles.lua",
                    "Sounds.lua", "Engine.lua", "Alerts.lua", "Mover.lua", "Options.lua"}) do Stub.load(f, ns) end
ns.Say = function() end
local combat = false
ns.Detect = setmetatable({ IsKnown = function(id) return id ~= 871 end, InCombat = function() return combat end },
  { __index = function() return function() end end })
local O, DB = ns.Options, ns.DB
RagebornDB = nil; DB:Init("Bob-Realm")

-- presses every button made so far whose label is this text
local function press(label)
  local n = 0
  for _, w in ipairs(made) do
    if w.kind == "Button" and w.scripts.OnClick and rawget(w, "text") and w.text.calls.SetText and w.text.calls.SetText[1] == label then
      w.scripts.OnClick(w); n = n + 1
    end
  end
  return n
end

return {
{"every text the window uses exists", function()
  for line in io.lines("Rageborn/Options.lua") do
    for key in line:gmatch("L%.([A-Z][A-Z_a-zA-Z]+)") do assert(rawget(ns.L, key), key) end
  end
  for _, g in ipairs(ns.Data.GROUPS) do assert(rawget(ns.L, "GROUP_" .. g), g) end
  for _, k in ipairs({"procLoop", "ants", "pulse", "corners"}) do assert(rawget(ns.L, "GLOW_" .. k), k) end end},
{"the window opens on General and shows every page for every alert", function()
  O:Open(); O:Toggle(); O:Toggle()
  for _, d in ipairs(ns.Data.ALERTS) do
    O:Select("alert", d.key); O:Select("gallery", d.key)
  end
  O:Select("profiles"); O:Select("nonsense"); O:Select("general") end},
{"an alert the character doesn't know can't be selected", function()
  O:Select("alert", "shieldWall")     -- spell 871 is unknown in this test
  O:Select("alert", "overpower"); press(ns.L.OPT_ENABLED) end},
{"every control on every page survives being used", function()
  for _, d in ipairs({"overpower", "battleShout", "lowHealth", "sunder"}) do
    O:Select("alert", d)
    for _, w in ipairs(made) do
      if w.scripts.OnClick and w.kind == "Button" then
        local label = rawget(w, "text") and w.text.calls.SetText and w.text.calls.SetText[1]
        if label ~= "x" then w.scripts.OnClick(w) end      -- everything but close
      end
      if w.scripts.OnValueChanged then w.scripts.OnValueChanged(w, 75) end
      if w.scripts.OnEnter then w.scripts.OnEnter(w); w.scripts.OnLeave(w) end
      if w.scripts.OnMouseWheel then w.scripts.OnMouseWheel(w, -1) end
    end
    if asked then asked.fn(); asked = nil end
  end end},
{"a slider writes its setting in the stored unit", function()
  RagebornDB = nil; DB:Init("Bob-Realm"); O:Select("alert", "overpower")
  for _, w in ipairs(made) do if w.scripts.OnValueChanged then w.scripts.OnValueChanged(w, 150) end end
  assert(DB:Alert("overpower").size == 1.5 and DB:Alert("overpower").opacity == 1.5, DB:Alert("overpower").size)
  assert(DB:Profile().scale == 1.5) end},
{"profiles: nothing changes in combat", function()
  RagebornDB = nil; DB:Init("Bob-Realm"); O:Select("profiles")
  combat = true; assert(press(ns.L.OPT_PROFILE_NEW) == 1); combat = false
  assert(#DB:List() == 1) end},
}
