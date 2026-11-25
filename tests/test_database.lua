local ns = Stub.load("Util.lua", {})
Stub.load("Data.lua", ns)
Stub.load("Database.lua", ns)
local DB = ns.DB
local function fresh(saved) RagebornDB = saved; DB:Init("Bob-Realm") end
-- the frame the database makes at its first Init to hear talent changes and the end of a fight
local watcher, realCreateFrame = nil, CreateFrame
CreateFrame = function() watcher = Stub.widget(); return watcher end
fresh(nil); CreateFrame = realCreateFrame
local spec, combat, said = nil, false, nil
ns.Detect = { Spec = function() return spec end, InCombat = function() return combat end }
ns.L = setmetatable({}, { __index = function(_, k) return k end }); ns.Say = function(t) said = t end
local function event(name) watcher.scripts.OnEvent(watcher, name) end
local function same(a, b)
  if type(a) ~= "table" or type(b) ~= "table" then return a == b end
  for k, v in pairs(a) do if not same(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end
local function refused(text, err)
  local ok, why = DB:Import("In", text); assert(ok == false and why == (err or "ERR_IMPORT"), tostring(text):sub(1, 40))
  assert(RagebornDB.profiles.In == nil)
end
return {
{"each preset enables exactly its alerts; Empty none; Standard the defaults", function()
  fresh(nil)
  for _, key in ipairs(DB.PRESETS) do
    assert(DB:Create(key, nil, key) == true); local alerts = RagebornDB.profiles[key].alerts
    for _, def in ipairs(ns.Data.ALERTS) do
      local want = def.defaultOn
      if key ~= "standard" then want = DB.PRESET_ALERTS[key][def.key] == true end
      assert(alerts[def.key].enabled == want, key .. " " .. def.key)
      assert(key ~= "empty" or alerts[def.key].enabled == false)
    end
  end
  local P = RagebornDB.profiles
  assert(P.prot.alerts.revenge.enabled and not P.prot.alerts.overpower.enabled and P.prot.alerts.battleShout.enabled)
  assert(P.arms.alerts.overpower.enabled and not P.arms.alerts.revenge.enabled and P.arms.alerts.lowHealth.enabled)
  assert(P.fury.alerts.deathWish.enabled and not P.fury.alerts.sunder.enabled and P.fury.alerts.interrupt.enabled)
  assert(P.arms.scale == 1 and P.arms.alerts.overpower.size == 1) end},
{"a preset may name alerts this version doesn't have", function()
  fresh(nil); DB.PRESET_ALERTS.arms.notYetMade = true; assert(DB:Create("A", nil, "arms") == true)
  assert(RagebornDB.profiles.A.alerts.notYetMade == nil); DB.PRESET_ALERTS.arms.notYetMade = nil end},
{"an unknown preset is refused and creates nothing", function()
  fresh(nil); assert(select(2, DB:Create("X", nil, "nope")) == "ERR_NO_PRESET"); assert(RagebornDB.profiles.X == nil)
  assert(select(2, DB:ApplyPreset("nope")) == "ERR_NO_PRESET"); assert(select(2, DB:ApplyPreset(nil)) == "ERR_NO_PRESET") end},
{"ApplyPreset changes only which alerts are on", function()
  fresh(nil); local n = 0; DB:OnChange(function() n = n + 1 end)
  DB:Profile().scale = 1.5; local a = DB:Alert("overpower"); a.size, a.x, a.style, a.color.r = 1.7, 33, "ring", 0.25
  local before = ns.U.DeepCopy(DB:Profile())
  assert(DB:ApplyPreset("prot") == true and n == 1)
  assert(a.enabled == false and DB:Alert("revenge").enabled == true and DB:Alert("sunder").enabled == true)
  for key, alert in pairs(DB:Profile().alerts) do before.alerts[key].enabled = alert.enabled end
  assert(same(before, DB:Profile()))
  DB:ApplyPreset("empty"); for _, alert in pairs(DB:Profile().alerts) do assert(alert.enabled == false) end
  DB:ApplyPreset("standard"); assert(a.enabled == true and DB:Alert("sunder").enabled == false and a.size == 1.7) end},
{"export then import gives the same profile, as printable text", function()
  fresh(nil); DB:ApplyPreset("fury"); DB:Profile().scale = 1.35; DB:Profile().critSound = "bell"
  local a = DB:Alert("execute"); a.size, a.x, a.y, a.style, a.color.g, a.showName = 1.25, -212.5, 40, "paint:execute_side1", 1 / 3, true
  DB:Profile().alerts.removedAlert = { size = 2 }; DB:Profile().window.x = 77
  local text = DB:Export(); assert(text:find("^RB1:%(") and not text:find("[^\33-\126]") and not text:find("window"))
  assert(DB:Import(" Copy ", text) == true); local copy = RagebornDB.profiles.Copy
  assert(copy.window.x == 0 and copy.alerts.removedAlert == nil)
  copy.window.x = 77; DB:Profile().alerts.removedAlert = nil; assert(same(copy, DB:Profile()))
  assert(DB:Import("Wrapped", " " .. text:sub(1, 200) .. "\r\n  " .. text:sub(201) .. "\n") == true)
  assert(same(RagebornDB.profiles.Wrapped.alerts, copy.alerts))
  assert(DB:Export("Copy") == DB:Export()); assert(select(2, DB:Export("Nope")) == "ERR_NO_PROFILE") end},
{"import keeps what it knows, fills the rest, ignores unknown keys and limits numbers", function()
  fresh(nil)
  assert(DB:Import("In", "RB1:(junk=(a=(b=(c=1))),scale=9,sounds=f,alerts=(nope=(size=1),overpower=(size=-3,sound='b%65ll',color=(r=7))))") == true)
  local p = RagebornDB.profiles.In
  assert(p.junk == nil and p.scale == 2 and p.sounds == false and p.enabled == true and p.alerts.nope == nil)
  local a = p.alerts.overpower; assert(a.size == 0.5 and a.sound == "bell" and a.color.r == 1 and a.color.g == 1 and a.opacity == 1)
  assert(p.alerts.revenge.enabled == true); assert(DB:Import("Bare", "RB1:()") == true) end},
{"import refuses garbage, another version, too much text and wrong types", function()
  fresh(nil)
  for _, text in ipairs({ "", "hello", "RB1", "RB1:", "RB1:(", "RB1:)", "RB1:(scale=1", "RB1:(scale=1)x", "RB1:(scale=1,)",
      "RB1:(=1)", "RB1:(scale)", "RB1:(scale=)", "RB1:(scale=1.2.3)", "RB1:(scale=0x10)", "RB1:(scale=1e999)", "RB1:(scale=nan)",
      "RB1:(scale=loadstring)", "RB1:(critSound='a|b')","RB1:(critSound='a%zz')", "RB1:(critSound='a%4')", "RB1:(critSound='a)",
      "RB1:(critSound=\"a\")", "RB1:{scale=1}", "RB1:(scale=1);os.exit()", "RB1:1", "RB1:t", "RB1:'x'", "rb1:(scale=1)",
      "RB1:(a=" .. ("("):rep(2000), "RB1:(a=" .. ("(a="):rep(20) .. "1" .. (")"):rep(21),
      "RB1:(scale='big')", "RB1:(scale=t)", "RB1:(enabled=1)", "RB1:(alerts=3)", "RB1:(alerts=(overpower=1))",
      "RB1:(alerts=(overpower=(size=t)))", "RB1:(alerts=(overpower=(color=5)))", "RB1:(alerts=(overpower=(style=(a=1))))",
      "RB1:(critSound='" .. ("a"):rep(65) .. "')" }) do refused(text) end
  for _, text in ipairs({ false, 5, {}, ("x"):rep(2 ^ 20), "RB1:(a='" .. ("x"):rep(2 ^ 20) .. "')" }) do refused(text) end
  refused(nil); refused("RB2:(scale=1)", "ERR_IMPORT_VERSION"); refused("RB10:()", "ERR_IMPORT_VERSION") end},
{"import never overwrites and follows Create's name rules", function()
  fresh(nil); local text = DB:Export(); DB:Create("Tank"); RagebornDB.profiles.Tank.scale = 1.5
  assert(select(2, DB:Import("Tank", text)) == "ERR_NAME_TAKEN"); assert(RagebornDB.profiles.Tank.scale == 1.5)
  assert(select(2, DB:Import(" Tank ", text)) == "ERR_NAME_TAKEN"); assert(select(2, DB:Import("Bob-Realm", text)) == "ERR_NAME_TAKEN")
  assert(select(2, DB:Import("  ", text)) == "ERR_NAME_EMPTY"); assert(select(2, DB:Import(nil, text)) == "ERR_NAME_EMPTY")
  local n = 0; DB:OnChange(function() n = n + 1 end); assert(DB:Import("New", text) == true and n == 1)
  assert(DB:Current() == "Bob-Realm") end},
{"talents pick the profile chosen for them", function()
  fresh(nil); DB:Create("Tank"); DB:Create("Dps"); DB:SetSpecProfile("prot", "Tank"); DB:SetSpecProfile("fury", "Dps")
  spec, combat, said = "prot", false, nil; event("PLAYER_TALENT_UPDATE")
  assert(DB:Current() == "Tank" and RagebornDB.chars["Bob-Realm"] == "Tank" and said)
  said = nil; event("PLAYER_LOGIN"); assert(DB:Current() == "Tank" and said == nil)      -- already on it
  spec = "fury"; assert(DB:SpecSwitch() == true and DB:Current() == "Dps")
  spec = "arms"; assert(DB:SpecSwitch() == false and DB:Current() == "Dps")             -- nothing chosen for Arms
  DB:Init("Al-Realm"); spec = "prot"; assert(DB:SpecSwitch() == false and DB:Current() == "Al-Realm") end},   -- per character
{"talents that can't be read change nothing", function()
  fresh(nil); DB:Create("Tank"); DB:SetSpecProfile("prot", "Tank")
  spec, combat = nil, false; event("PLAYER_TALENT_UPDATE"); assert(DB:Current() == "Bob-Realm")
  ns.Detect.Spec = function() return "nonsense" end; assert(DB:SpecSwitch() == false)
  ns.Detect.Spec = function() return spec end; local D = ns.Detect; ns.Detect = nil; assert(DB:SpecSwitch() == false); ns.Detect = D end},
{"a deleted or renamed profile in the talent choice", function()
  fresh(nil); DB:Create("Tank"); DB:SetSpecProfile("prot", "Tank"); DB:SetSpecProfile("arms", "Gone")
  spec, combat = "arms", false; assert(DB:SpecSwitch() == false and DB:Current() == "Bob-Realm" and DB:SpecProfile("arms") == nil)
  DB:Rename("Tank", "Prot"); assert(DB:SpecProfile("prot") == "Prot")
  DB:Delete("Prot"); assert(DB:SpecProfile("prot") == nil and RagebornDB.specs["Bob-Realm"].prot == nil)
  spec = "prot"; assert(DB:SpecSwitch() == false and DB:Current() == "Bob-Realm") end},
{"a talent switch in combat waits for the end of the fight", function()
  fresh(nil); DB:Create("Tank"); DB:SetSpecProfile("prot", "Tank")
  spec, combat = "prot", false; event("PLAYER_REGEN_ENABLED"); assert(DB:Current() == "Bob-Realm")   -- nothing was waiting
  combat = true; event("PLAYER_TALENT_UPDATE"); assert(DB:Current() == "Bob-Realm")
  combat = false; event("PLAYER_REGEN_ENABLED"); assert(DB:Current() == "Tank")
  DB:Use("Bob-Realm"); event("PLAYER_REGEN_ENABLED"); assert(DB:Current() == "Bob-Realm") end},      -- once only
{"the spec is the talent tree with the most points, in either shape the client answers", function()
  local D = Stub.load("Detect.lua", Stub.load("Util.lua", {})).Detect
  local old = { GetTalentTabInfo, GetNumTalents, GetTalentInfo }
  local pts = { 5, 31, 15 }
  GetTalentTabInfo = function(tab) return "Tree", "icon", pts[tab] end; assert(D.Spec() == "fury")
  GetTalentTabInfo = function(tab) return 100 + tab, "Tree", "text", "icon", pts[tab] end
  assert(D.Spec() == "fury"); pts = { 8, 12, 31 }; assert(D.Spec() == "prot"); pts = { 40, 11, 0 }; assert(D.Spec() == "arms")
  pts = { 20, 20, 11 }; assert(D.Spec() == nil); pts = { 0, 0, 0 }; assert(D.Spec() == nil)
  pts = { 5, Stub.secret(), 15 }; GetNumTalents, GetTalentInfo = nil, nil; assert(D.Spec() == nil)
  GetTalentTabInfo = function() error("gone") end; assert(D.Spec() == nil)
  GetNumTalents = function() return 2 end                                        -- no tab totals: count the ranks
  GetTalentInfo = function(tab, i) return "T", "icon", 1, i, tab == 3 and 5 or 1 end; assert(D.Spec() == "prot")
  GetTalentTabInfo = nil; assert(D.Spec() == "prot"); GetNumTalents = nil; assert(D.Spec() == nil)
  GetTalentTabInfo, GetNumTalents, GetTalentInfo = old[1], old[2], old[3] end},
{"an old or corrupt save gets its talent choices", function()
  fresh({ profiles = {}, chars = {}, specs = "x" }); assert(DB:SpecProfile("prot") == nil)
  fresh({ profiles = {}, chars = {}, specs = { ["Bob-Realm"] = 5 } }); DB:SetSpecProfile("prot", "Bob-Realm")
  assert(DB:SpecProfile("prot") == "Bob-Realm")
  fresh({ profiles = {}, chars = {}, specs = { ["Bob-Realm"] = { prot = 7 }, Other = "junk" } }); spec = "prot"
  assert(DB:SpecSwitch() == false); DB:Create("T"); DB:Rename("T", "U"); DB:Delete("U") end},
{"fresh install creates the character's own profile", function()
  fresh(nil); assert(DB:Current() == "Bob-Realm"); assert(DB:Profile().enabled == true)
  assert(RagebornDB.chars["Bob-Realm"] == "Bob-Realm") end},
{"alert defaults come from the alert's definition", function()
  fresh(nil); local a = DB:Alert("battleShout")
  assert(a.enabled == true and a.style == "frame" and a.threshold == 3)
  assert(DB:Alert("bloodrage").enabled == false); assert(DB:Alert("lowHealth").threshold == 35) end},
{"an alert with painted art starts on it once styles are loaded", function()
  local n2 = Stub.load("Util.lua", {}); Stub.load("Locale.lua", n2); Stub.load("Data.lua", n2)
  n2.Styles = { DefaultFor = function(def) return def.key == "overpower" and "paint:overpower_side1" or def.defaultStyle end }
  Stub.load("Database.lua", n2); RagebornDB = nil; n2.DB:Init("Bob-Realm")
  assert(n2.DB:Alert("overpower").style == "paint:overpower_side1"); assert(n2.DB:Alert("shieldWall").style == "ring") end},
{"alert defaults for the look", function()
  fresh(nil); local a = DB:Alert("overpower")
  assert(a.side == "both" and a.recolor == false)
  assert(a.size == 1 and a.opacity == 1 and a.spread == 1 and a.showIcon == true and a.showTimer == true)
  assert(a.sound == "none" and a.glow == true and a.glowStyle == "procLoop" and a.stanceHint == true)
  assert(type(a.color.r) == "number" and type(a.glowColor.b) == "number")
  assert(type(a.x) == "number" and type(a.y) == "number") end},
{"old save gets new keys, keeps old values", function()
  fresh({profiles = {P = {scale = 2, alerts = {overpower = {size = 3, enabled = false}}}}, chars = {["Bob-Realm"] = "P"}})
  assert(DB:Current() == "P"); assert(DB:Profile().scale == 2)
  assert(DB:Alert("overpower").size == 3 and DB:Alert("overpower").enabled == false)
  assert(DB:Alert("overpower").opacity == 1); assert(DB:Alert("revenge").enabled == true) end},
{"character pointing at a deleted profile falls back to its own", function()
  fresh({profiles = {}, chars = {["Bob-Realm"] = "Gone"}}); assert(DB:Current() == "Bob-Realm") end},
{"unknown alert key in the save is ignored, not an error", function()
  fresh({profiles = {P = {alerts = {removedAlert = {size = 2}}}}, chars = {["Bob-Realm"] = "P"}})
  assert(DB:Alert("removedAlert") == nil) end},
{"corrupt saves are replaced", function()
  fresh("x"); assert(DB:Profile().enabled == true)
  fresh({profiles = "x", chars = 5}); assert(DB:Profile().enabled == true)
  fresh({profiles = {["Bob-Realm"] = "x"}, chars = {}}); assert(DB:Profile().enabled == true) end},
{"two characters keep separate profiles by default", function()
  fresh(nil); DB:Profile().scale = 1.5; DB:Init("Al-Realm"); assert(DB:Profile().scale == 1)
  DB:Init("Bob-Realm"); assert(DB:Profile().scale == 1.5) end},
{"Create copies, and the copy is independent", function()
  fresh(nil); DB:Profile().scale = 1.5; assert(DB:Create("Tank", DB:Current()) == true)
  DB:Use("Tank"); assert(DB:Profile().scale == 1.5); DB:Profile().scale = 3
  DB:Use("Bob-Realm"); assert(DB:Profile().scale == 1.5) end},
{"Create without a source starts from defaults", function()
  fresh(nil); DB:Profile().scale = 1.5; assert(DB:Create("Clean")); DB:Use("Clean"); assert(DB:Profile().scale == 1) end},
{"Create refuses empty and taken names and a missing source", function()
  fresh(nil); DB:Create("Tank")
  assert(select(2, DB:Create("  ")) == "ERR_NAME_EMPTY"); assert(select(2, DB:Create(nil)) == "ERR_NAME_EMPTY")
  assert(select(2, DB:Create("Tank")) == "ERR_NAME_TAKEN"); assert(select(2, DB:Create("X", "Nope")) == "ERR_NO_PROFILE") end},
{"Create trims the name", function() fresh(nil); DB:Create("  Tank "); DB:Use("Tank"); assert(DB:Current() == "Tank") end},
{"Use an unknown profile is refused and changes nothing", function()
  fresh(nil); assert(select(2, DB:Use("Nope")) == "ERR_NO_PROFILE"); assert(DB:Current() == "Bob-Realm") end},
{"Rename moves the profile and every character using it", function()
  fresh(nil); DB:Create("Tank"); DB:Use("Tank"); RagebornDB.chars["Al-Realm"] = "Tank"
  assert(DB:Rename("Tank", "Prot") == true); assert(DB:Current() == "Prot")
  assert(RagebornDB.chars["Al-Realm"] == "Prot" and RagebornDB.profiles.Tank == nil)
  assert(select(2, DB:Rename("Prot", "Bob-Realm")) == "ERR_NAME_TAKEN")
  assert(select(2, DB:Rename("Nope", "Z")) == "ERR_NO_PROFILE"); assert(select(2, DB:Rename("Prot", " ")) == "ERR_NAME_EMPTY") end},
{"Delete refuses the current profile and unknown ones", function()
  fresh(nil); assert(select(2, DB:Delete(DB:Current())) == "ERR_PROFILE_IN_USE")
  assert(select(2, DB:Delete("Nope")) == "ERR_NO_PROFILE") end},
{"Delete sends other characters on it back to their own profile", function()
  fresh(nil); DB:Create("Tank"); RagebornDB.chars["Al-Realm"] = "Tank"; assert(DB:Delete("Tank") == true)
  DB:Init("Al-Realm"); assert(DB:Current() == "Al-Realm") end},
{"Reset restores defaults for the current profile only", function()
  fresh(nil); DB:Profile().scale = 1.5; DB:Create("Tank"); DB:Use("Tank"); DB:Profile().scale = 9
  DB:Alert("overpower").size = 4; DB:Reset(); assert(DB:Profile().scale == 1 and DB:Alert("overpower").size == 1)
  DB:Use("Bob-Realm"); assert(DB:Profile().scale == 1.5) end},
{"List is sorted", function()
  fresh(nil); DB:Create("Zed"); DB:Create("Alpha"); local l = DB:List()
  assert(l[1] == "Alpha" and l[2] == "Bob-Realm" and l[3] == "Zed") end},
{"the talent switch happens when the spec changes, and leaves a profile picked by hand alone", function()
  fresh(nil); DB:Create("A"); DB:Create("B"); DB:SetSpecProfile("fury", "A")
  spec, combat = "fury", false; assert(DB:SpecSwitch() == true and DB:Current() == "A")
  DB:Use("B"); assert(DB:SpecSwitch() == false and DB:Current() == "B")          -- same spec: stays
  DB:Init("Bob-Realm"); assert(DB:SpecSwitch() == false and DB:Current() == "B") -- also at the next login
  spec = "prot"; DB:SpecSwitch(); spec = "fury"; assert(DB:SpecSwitch() == true and DB:Current() == "A")
  DB:Use("B"); DB:SetSpecProfile("fury", "A"); assert(DB:SpecSwitch() == true) end},    -- a new choice applies
{"an older save: a visible glow-only alert stays visible, and a new threshold gets its default", function()
  fresh({ profiles = { ["Bob-Realm"] = { alerts = { racial = { opacity = 0.8 }, fearBreak = { opacity = 0 },
          sunder = { threshold = 0 }, lowHealth = { threshold = 20 } } } }, chars = {} })
  assert(DB:Alert("racial").onScreen == true and DB:Alert("fearBreak").onScreen == false)
  assert(DB:Alert("sunder").threshold == 5 and DB:Alert("lowHealth").threshold == 20)
  DB:Alert("racial").onScreen = false; DB:Init("Bob-Realm"); assert(DB:Alert("racial").onScreen == false) end},
{"a shared profile doesn't carry the window or the minimap button", function()
  fresh(nil); DB:Profile().minimap.hide = true; DB:Profile().window.x = 99
  assert(not DB:Export("Bob-Realm"):find("minimap") and not DB:Export("Bob-Realm"):find("window"))
  assert(DB:Import("In", DB:Export("Bob-Realm")) == true)
  assert(RagebornDB.profiles.In.minimap.hide == false and RagebornDB.profiles.In.window.x == 0) end},
{"every alert a preset names exists", function()
  for name, set in pairs(DB.PRESET_ALERTS) do
    for key in pairs(set) do assert(ns.Data.BY_KEY[key], name .. " " .. key) end
  end end},
{"OnChange fires after Use, Create, Rename, Delete and Reset", function()
  fresh(nil); local n = 0; DB:OnChange(function() n = n + 1 end)
  DB:Create("A"); DB:Use("A"); DB:Rename("A", "B"); DB:Reset(); DB:Use("Bob-Realm"); DB:Delete("B"); assert(n == 6, n)
  DB:Create(" "); assert(n == 6) end},
}
