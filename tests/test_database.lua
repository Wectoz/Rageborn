local ns = Stub.load("Util.lua", {})
Stub.load("Data.lua", ns)
Stub.load("Database.lua", ns)
local DB = ns.DB
local function fresh(saved) RagebornDB = saved; DB:Init("Bob-Realm") end
return {
{"fresh install creates the character's own profile", function()
  fresh(nil); assert(DB:Current() == "Bob-Realm"); assert(DB:Profile().enabled == true)
  assert(RagebornDB.chars["Bob-Realm"] == "Bob-Realm") end},
{"alert defaults come from the alert's definition", function()
  fresh(nil); local a = DB:Alert("battleShout")
  assert(a.enabled == true and a.style == "frame" and a.threshold == 3)
  assert(DB:Alert("bloodrage").enabled == false); assert(DB:Alert("lowHealth").threshold == 35) end},
{"alert defaults for the look", function()
  fresh(nil); local a = DB:Alert("overpower")
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
{"OnChange fires after Use, Create, Rename, Delete and Reset", function()
  fresh(nil); local n = 0; DB:OnChange(function() n = n + 1 end)
  DB:Create("A"); DB:Use("A"); DB:Rename("A", "B"); DB:Reset(); DB:Use("Bob-Realm"); DB:Delete("B"); assert(n == 6, n)
  DB:Create(" "); assert(n == 6) end},
}
