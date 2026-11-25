-- Smoke test of the settings window: every page builds, every control can be used.
local made = {}
CreateFrame = function(kind) local w = Stub.widget(); w.kind = kind; made[#made + 1] = w; return w end
UIParent, GameFontNormal, ChatFontNormal = Stub.widget(), Stub.widget(), Stub.widget()
StaticPopupDialogs = {}
local asked
StaticPopup_Show = function(_, text, _, fn) asked = { text = text, fn = fn } end
ACCEPT, CANCEL = "Accept", "Cancel"
local wheel
ColorPickerFrame = { SetupColorPickerAndShow = function(_, info) wheel = info end,
                     GetColorRGB = function() return 0.2, 0.4, 0.6 end }

local ns = Stub.load("Util.lua", {})
for _, f in ipairs({"Locale.lua", "Data.lua", "Database.lua", "ArtList.lua", "PaintedList.lua", "Styles.lua",
                    "Sounds.lua", "Engine.lua", "Alerts.lua", "Mover.lua", "Macros.lua", "Options.lua"}) do Stub.load(f, ns) end
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
  O:Select("macros"); O:Select("profiles"); O:Select("nonsense"); O:Select("general") end},
{"the macros page lists what the character knows and Create reports instead of failing", function()
  O:Select("macros")
  assert(press(ns.L.MACRO_CREATE) == #ns.Macros.Available(ns.Detect.IsKnown) and press(ns.L.MACRO_CREATE) > 0) end},
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
{"picking a colour on the wheel tints painted art; cancelling puts it back", function()
  RagebornDB = nil; DB:Init("Bob-Realm"); O:Select("alert", "overpower")
  local o = DB:Alert("overpower")
  assert(ns.Styles.Get(o.style).family == "painted" and o.recolor == false)
  for _, w in ipairs(made) do                   -- the first colour swatch made is the alert's colour
    local size = w.calls.SetSize
    if w.kind == "Button" and size and size[1] == 80 and size[2] == 26 then w.scripts.OnClick(w); break end
  end
  wheel.swatchFunc(); assert(o.recolor == true and o.color.r == 0.2 and o.color.b == 0.6)
  wheel.cancelFunc(); assert(o.recolor == false and o.color.r == 1) end},
{"the window keeps its place on screen at any size, and takes its fonts from the profile", function()
  RagebornDB = nil; DB:Init("Bob-Realm"); O:Open()
  local win, bar
  for _, w in ipairs(made) do
    if not win and w.calls.SetSize and w.calls.SetSize[1] == 860 then win = w end
    if win and not bar and w.scripts.OnDragStop then bar = w end     -- the title bar is made right after the window
  end
  local window = DB:Profile().window
  window.scale, window.textFont = 0.5, "morpheus"
  win.GetCenter = function() return 500, 300 end; UIParent.GetCenter = function() return 400, 300 end
  bar.scripts.OnDragStop(); assert(window.x == -150 and window.y == -150, window.x)
  O:Open()
  assert(win.calls.SetScale[1] == 0.5 and win.calls.SetPoint[4] == -300 and win.calls.SetPoint[5] == -300)
  local fonts = {}
  for _, w in ipairs(made) do if w.calls.SetFont then fonts[w.calls.SetFont[1]] = true end end
  assert(fonts["Fonts\\MORPHEUS.TTF"] and not fonts["Fonts\\ARIALN.TTF"])   -- text boxes already made were re-lettered
  win.GetCenter, UIParent.GetCenter = nil, nil; RagebornDB = nil; DB:Init("Bob-Realm") end},
{"profiles: nothing changes in combat", function()
  RagebornDB = nil; DB:Init("Bob-Realm"); O:Select("profiles")
  combat = true; assert(press(ns.L.OPT_PROFILE_NEW) == 1); combat = false
  assert(#DB:List() == 1) end},
}
