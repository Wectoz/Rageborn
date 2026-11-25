-- Smoke test of Alerts and Sounds against a widget that accepts any call.
local widget = Stub.widget
CreateFrame = function() return widget() end
UIParent, GameFontNormal = widget(), widget()
local played = {}
PlaySound = function(kit) played[#played + 1] = kit end

local ns = Stub.load("Util.lua", {})
for _, f in ipairs({"Locale.lua", "Data.lua", "Database.lua", "ArtList.lua", "PaintedList.lua", "Styles.lua",
                    "Sounds.lua", "Alerts.lua"}) do Stub.load(f, ns) end
local A, DB = ns.Alerts, ns.DB
-- sounds are off in a new profile; these tests turn them on
local function reset() RagebornDB = nil; DB:Init("Bob-Realm"); DB:Profile().sounds = true; played = {}; Stub.now = 100 end
local function alpha(key) return A:Frame(key).calls.SetAlpha[1] end

return {
{"sound list: none, ten game sounds, then spell sounds of all nine classes; unique keys", function()
  assert(#ns.Sounds.LIST == 78 and ns.Sounds.LIST[1].key == "none" and ns.Sounds.LIST[1].kit == nil)
  local classes, n = {}, 0
  for _, s in ipairs(ns.Sounds.LIST) do
    if s.class then
      assert(s.label:match("^%u%l+: .") and not s.label:match("^CLASS_"), s.label)
      if not classes[s.class] then classes[s.class] = true; n = n + 1 end
    end
  end
  assert(n == 9 and classes.WARRIOR and classes.WARLOCK)
  local seen = {}
  for i, s in ipairs(ns.Sounds.LIST) do
    assert(not seen[s.key] and type(s.label) == "string" and not s.label:match("^SOUND_"), s.key); seen[s.key] = true
    assert(i == 1 or type(s.kit) == "number", s.key)
  end end},
{"Play plays the kit; none and unknown keys are silent", function()
  reset(); ns.Sounds.Play("none"); ns.Sounds.Play("gone"); ns.Sounds.Play(nil); assert(#played == 0)
  ns.Sounds.Play("raidWarning"); assert(played[1] == 8959) end},
{"a crit on the target plays the crit sound, once for hits that land together", function()
  reset(); local S = ns.Sounds; DB:Profile().critSound = "bell"
  S.OnCombat("target", "WOUND", "CRITICAL", 10); S.OnCombat("target", "WOUND", "CRITICAL", 10.1)
  assert(#played == 1 and played[1] == 6594)
  S.OnCombat("target", "WOUND", nil, 11); S.OnCombat("player", "WOUND", "CRITICAL", 11)
  S.OnCombat("target", "DODGE", "CRITICAL", 11); S.OnCombat(nil, nil, nil, 11); assert(#played == 1)
  S.OnCombat("target", "WOUND", "CRITICAL", 11); assert(#played == 2) end},
{"every sound is off in a new profile; the sounds switch silences everything but a try-out", function()
  RagebornDB = nil; DB:Init("Bob-Realm")
  assert(DB:Profile().critSound == "none" and DB:Profile().sounds == false and DB:Alert("overpower").sound == "none")
  reset(); local S = ns.Sounds
  S.OnCombat("target", "WOUND", "CRITICAL", 20); assert(#played == 0)
  DB:Profile().sounds = false; S.Play("bell"); assert(#played == 0); S.Play("bell", true); assert(#played == 1) end},
{"Find matches a key or a label whatever the capitals", function()
  local S = ns.Sounds
  assert(S.Find("RAIDWARNING").key == "raidWarning" and S.Find("raid warning").key == "raidWarning")
  assert(S.Find("none").key == "none" and S.Find("") == nil and S.Find(nil) == nil) end},
{"an alert appears, plays its sound once, fades and hides", function()
  reset(); DB:Alert("overpower").sound = "readyCheck"
  A:OnAlert("overpower", true, { spellID = 7384, expires = 105, duration = 5 })
  local f = A:Frame("overpower"); assert(f.shown == true and #played == 1)
  A:Update(100.05, 0.05)
  A:OnAlert("overpower", true, { spellID = 7384, expires = 104, duration = 5 })   -- news while shown: no sound
  A:Update(101, 0.05); assert(#played == 1 and alpha("overpower") > 0.75)
  Stub.now = 101; A:OnAlert("overpower", false)
  Stub.now = 101.05; A:OnAlert("overpower", false)   -- told twice: the fade doesn't restart
  A:Update(101.1, 0.1); assert(f.shown == true and alpha("overpower") < 0.6)
  A:Update(101.3, 0.2); assert(f.shown == false)
  Stub.now = 102; A:OnAlert("overpower", true, { spellID = 7384 }); assert(f.shown == true and #played == 2) end},
{"dim halves the opacity", function()
  reset(); A:OnAlert("battleShout", true, { spellID = 6673, dim = true })
  A:Update(100, 0); assert(math.abs(alpha("battleShout") - 0.45) < 0.01) end},
{"an alert not shown on screen never shows its frame, but sounds and reaches the other subscribers", function()
  reset(); local subs, heard = {}, {}
  ns.Engine = { Subscribe = function(_, fn) subs[#subs + 1] = fn end }
  A:Start(); ns.Engine:Subscribe(function(key, shown) heard[#heard + 1] = key .. tostring(shown) end)
  local function tell(...) for _, fn in ipairs(subs) do fn(...) end end
  local o = DB:Alert("racial"); assert(o.onScreen == false and o.opacity == 1 and DB:Alert("overpower").onScreen == true)
  o.sound = "bell"; tell("racial", true, { spellID = 20589 }); tell("racial", true, { spellID = 20589 })
  local f = A:Frame("racial"); A:Update(100.5, 0.02)
  assert(f.shown == false and f.calls.SetAlpha == nil and #played == 1 and played[1] == 6594)
  assert(heard[1] == "racialtrue" and #heard == 2)
  o.onScreen = true; A:Apply("racial"); assert(f.shown == true)          -- switched on while it is up
  o.onScreen = false; A:Apply("racial"); assert(f.shown == false)
  local p = A:Preview("racial", widget()); A:Update(101, 0.02)             -- the settings preview still draws
  assert(p.shown == true and p.calls.SetAlpha[1] > 0.8)
  tell("racial", false); A:Update(102, 0.02); tell("racial", true, { spellID = 20589 })
  assert(f.shown == false and #played == 2) end},
{"position is the saved offset from the screen centre whatever the size", function()
  reset(); local o = DB:Alert("execute"); o.x, o.y, o.size = 100, -50, 2; DB:Profile().scale = 1
  A:Apply("execute"); local p = A:Frame("execute").calls.SetPoint
  A:Apply("execute"); p = A:Frame("execute").calls.SetPoint
  assert(p[4] == 50 and p[5] == -25 and A:Frame("execute").calls.SetScale[1] == 2) end},
{"every alert draws in every style, and a preview runs", function()
  reset()
  for _, d in ipairs(ns.Data.ALERTS) do
    for _, st in ipairs({"ring", "arcs", "frame", "bar", "vignette", "gameArt", "paint:overpower_side1", "gone"}) do
      DB:Alert(d.key).style = st; A:Apply(d.key)
      A:OnAlert(d.key, true, { spellID = d.spells and d.spells[1], expires = 110, duration = 10, stacks = 2, hintStance = 1 })
      A:Update(100.5, 0.02)
    end
  end
  local p = A:Preview("lowHealth", widget()); A:Update(100.5, 0.02); A:Update(111, 0.02); assert(p.shown == true) end},
}
