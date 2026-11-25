local ns = Stub.load("Util.lua", {})
Stub.load("Locale.lua", ns); Stub.load("Data.lua", ns); Stub.load("Database.lua", ns)
Stub.load("Engine.lua", ns)
local E, DB = ns.Engine, ns.DB

local fake
local function reset()
  RagebornDB = nil; DB:Init("Bob-Realm")
  for _, d in ipairs(ns.Data.ALERTS) do DB:Alert(d.key).enabled = true; DB:Alert(d.key).combatOnly = false end
  fake = { known = true, usable = false, lacksRage = false, cd = 0, hp = {player = 100, target = 100},
           buff = nil, debuff = nil, stance = 1, casting = false, shield = true, queued = false,
           combat = true, quiet = false, enemies = 0, wrong = {} }
  ns.Detect = {
    IsKnown = function(id) if type(fake.known) == "table" then return fake.known[id] == true end return fake.known end,
    Usable = function() return fake.usable, fake.lacksRage end,
    CooldownLeft = function(id) if type(fake.cd) == "table" then return fake.cd[id] end return fake.cd end,
    HealthPct = function(unit) return fake.hp[unit] end,
    PlayerBuff = function() if fake.buff then return fake.buff.expires, fake.buff.duration end end,
    TargetDebuff = function() if fake.debuff then return fake.debuff.stacks, fake.debuff.expires end end,
    Stance = function() return fake.stance end, TargetCasting = function() return fake.casting end,
    HasShield = function() return fake.shield end, IsQueued = function() return fake.queued end,
    InCombat = function() return fake.combat end, Enemies = function() return fake.enemies end, Afflictions = function() return fake.wrong end, Quiet = function() return fake.quiet end,
  }
  E:Reset()
end
local function T(name, fn) return {name, function() reset(); fn() end} end

return {
T("usable alert shows when usable", function() fake.usable = true; assert(E:Evaluate("execute", 1) == true) end),
T("usable alert is hidden when not usable", function() assert(E:Evaluate("execute", 1) == false) end),
T("execute: lacking only rage shows when the target is under 20%", function()
  fake.lacksRage = true; fake.hp.target = 15; assert(E:Evaluate("execute", 1) == true) end),
T("execute: lacking rage does not show on a healthy target", function()
  fake.lacksRage = true; fake.hp.target = 80; assert(E:Evaluate("execute", 1) == false) end),
T("execute: lacking rage with unreadable target health stays hidden", function()
  fake.lacksRage = true; fake.hp.target = nil; assert(E:Evaluate("execute", 1) == false) end),
T("overpower: lacking only rage shows while the dodge window is open", function()
  fake.lacksRage = true; assert(E:Evaluate("overpower", 1) == false)
  E:OnMiss("target", "DODGE", 10); assert(E:Evaluate("overpower", 11) == true) end),
T("Demo Shout on a pull: enough enemies, in combat, ready, and not just cast", function()
  fake.usable = true; assert(E:Evaluate("demoPull", 1) == false)                 -- one enemy
  fake.enemies = 3; assert(E:Evaluate("demoPull", 1) == true)
  fake.combat = false; assert(E:Evaluate("demoPull", 1) == false); fake.combat = true
  fake.enemies = nil; assert(E:Evaluate("demoPull", 1) == false); fake.enemies = 3    -- unreadable
  DB:Alert("demoPull").threshold = 4; assert(E:Evaluate("demoPull", 1) == false); DB:Alert("demoPull").threshold = 2
  fake.cd = 5; assert(E:Evaluate("demoPull", 1) == false); fake.cd = 0
  fake.debuff = { stacks = 0, expires = 20 }; assert(E:Evaluate("demoPull", 1) == false); fake.debuff = nil
  E:OnCast(11556, 10); assert(E:Evaluate("demoPull", 11) == false); assert(E:Evaluate("demoPull", 41) == true) end),
T("the racial shows when it would help and is ready, and is glow-only by default", function()
  fake.usable = true; fake.known = {[20589] = true}                -- a gnome
  assert(E:Evaluate("racial", 1) == false)                          -- nothing wrong
  fake.wrong = {STUN = true}; assert(E:Evaluate("racial", 1) == false)   -- Escape Artist doesn't break a stun
  fake.wrong = {SNARE = true}
  local s, i = E:Evaluate("racial", 1); assert(s == true and i.spellID == 20589)
  fake.cd = 90; assert(E:Evaluate("racial", 2) == false); fake.cd = 0
  fake.known = {[59752] = true}; assert(E:Evaluate("racial", 3) == false)      -- a human, slowed
  fake.wrong = {STUN = true}; assert(E:Evaluate("racial", 3) == true)
  fake.wrong = nil; assert(E:Evaluate("racial", 4) == false)                   -- unreadable
  assert(DB:Alert("racial").opacity == 0 and DB:Alert("racial").glow == true and DB:Alert("overpower").opacity == 1) end),
T("unknown spell never shows", function()
  fake.known = false; fake.usable = true; local s, i = E:Evaluate("execute", 1); assert(s == false and i == nil) end),
T("the highest known rank is reported", function()
  fake.known = {[5308] = true, [20658] = true}; fake.usable = true
  local _, i = E:Evaluate("execute", 1); assert(i.spellID == 20658) end),
T("disabled alert never shows", function()
  fake.usable = true; DB:Alert("execute").enabled = false; assert(E:Evaluate("execute", 1) == false) end),
T("master switch off hides everything", function()
  fake.usable = true; DB:Profile().enabled = false; assert(E:Evaluate("execute", 1) == false) end),
T("an alert this version doesn't have is hidden, no error", function() assert(E:Evaluate("nope", 1) == false) end),
T("Usable returning nil keeps the last answer", function()
  fake.usable = true;  assert(E:Evaluate("execute", 1) == true)
  fake.usable = nil;   assert(E:Evaluate("execute", 2) == true)
  fake.usable = false; assert(E:Evaluate("execute", 3) == false)
  fake.usable = nil;   assert(E:Evaluate("execute", 4) == false) end),
T("overpower: target dodge in the wrong stance shows a hint for 5 s", function()
  fake.stance = 2; E:OnMiss("target", "DODGE", 10)
  local s, i = E:Evaluate("overpower", 11); assert(s == true and i.hintStance == 1)
  assert(E:Evaluate("overpower", 15.1) == false) end),
T("overpower: no hint in the right stance (the game's answer rules)", function()
  fake.stance = 1; E:OnMiss("target", "DODGE", 10); assert(E:Evaluate("overpower", 11) == false) end),
T("overpower hint is off when stanceHint is off", function()
  fake.stance = 2; DB:Alert("overpower").stanceHint = false; E:OnMiss("target", "DODGE", 10)
  assert(E:Evaluate("overpower", 11) == false) end),
T("the window gives the alert a timer", function()
  fake.usable = true; E:OnMiss("target", "DODGE", 10)
  local _, i = E:Evaluate("overpower", 12); assert(i.remaining == 3 and i.duration == 5 and i.expires == 15) end),
T("revenge window opens on player dodge, parry and block, not on target dodge", function()
  fake.stance = 1
  for n, kind in ipairs({"DODGE", "PARRY", "BLOCK"}) do
    E:Reset(); E:OnMiss("player", kind, n * 100); assert(E:Evaluate("revenge", n * 100 + 1) == true, kind) end
  E:Reset(); E:OnMiss("target", "DODGE", 10); assert(E:Evaluate("revenge", 11) == false)
  E:Reset(); E:OnMiss("player", "MISS", 10); assert(E:Evaluate("revenge", 11) == false) end),
T("casting the spell closes its window", function()
  fake.stance = 2; E:OnMiss("target", "DODGE", 10); assert(E:Evaluate("overpower", 11) == true)
  E:OnCast(7384, 12); assert(E:Evaluate("overpower", 12.5) == false) end),
T("victory rush opens for 20 s on a kill", function()
  fake.lacksRage = true; E:OnKill(100); assert(E:Evaluate("victoryRush", 119) == true)
  assert(E:Evaluate("victoryRush", 120.5) == false) end),
T("active: cast starts a timer of the data duration, estimated", function()
  E:OnCast(871, 100); local s, i = E:Evaluate("shieldWall", 104)
  assert(s == true and i.remaining == 6 and i.duration == 10 and i.estimated == true and i.expires == 110) end),
T("active: hidden before any cast and after the duration", function()
  assert(E:Evaluate("shieldWall", 50) == false); E:OnCast(871, 100); assert(E:Evaluate("shieldWall", 110.1) == false) end),
T("active: a lower rank ID of the same spell also starts it", function()
  E:OnCast(6673, 100); fake.buff = nil; fake.combat = true
  E:OnCast(78, 100)   -- a low rank of Heroic Strike is not an "active" timer
  E:OnCast(2565, 100); assert(E:Evaluate("shieldBlockUp", 103) == true) end),
T("a cast with an unreadable spell ID is ignored", function() E:OnCast(nil, 100); assert(E:Evaluate("shieldWall", 101) == false) end),
T("queued: shows while Heroic Strike or Cleave is queued", function()
  assert(E:Evaluate("queued", 1) == false); fake.queued = true; assert(E:Evaluate("queued", 2) == true) end),
T("battle shout: missing out of combat shows dim", function()
  fake.combat = false; local s, i = E:Evaluate("battleShout", 10); assert(s == true and i.dim == true) end),
T("battle shout: hidden while Quiet", function()
  fake.combat = false; fake.quiet = true; assert(E:Evaluate("battleShout", 10) == false) end),
T("battle shout: shows 3 s before expiry", function()
  fake.combat = false; fake.buff = {expires = 50, duration = 120}
  assert(E:Evaluate("battleShout", 46.9) == false); assert(E:Evaluate("battleShout", 47.1) == true) end),
T("battle shout: the warning time follows the setting", function()
  fake.combat = false; fake.buff = {expires = 50, duration = 120}; DB:Alert("battleShout").threshold = 10
  assert(E:Evaluate("battleShout", 41) == true) end),
T("battle shout in combat with the buff unreadable runs on the last known expiry", function()
  fake.combat = false; fake.buff = {expires = 200, duration = 120}; E:Evaluate("battleShout", 100)
  fake.buff = nil; fake.combat = true
  assert(E:Evaluate("battleShout", 190) == false); assert(E:Evaluate("battleShout", 198) == true) end),
T("battle shout: missing when combat starts stays shown in combat, not dim", function()
  fake.combat = false; E:Evaluate("battleShout", 10); fake.combat = true
  local s, i = E:Evaluate("battleShout", 12); assert(s == true and not i.dim) end),
T("battle shout: own cast in combat restarts the estimate at 120 s", function()
  fake.combat = true; E:OnCast(11551, 300)
  assert(E:Evaluate("battleShout", 400) == false); assert(E:Evaluate("battleShout", 418) == true) end),
T("battle shout: gone when read out of combat clears the estimate", function()
  E:OnCast(6673, 300); fake.combat = false; fake.buff = nil; assert(E:Evaluate("battleShout", 310) == true) end),
T("low health: shows below threshold when a checked defensive is ready", function()
  fake.hp.player = 30; assert(E:Evaluate("lowHealth", 1) == true)
  fake.hp.player = 36; assert(E:Evaluate("lowHealth", 2) == false) end),
T("low health: hidden when every checked defensive is on cooldown", function()
  fake.hp.player = 20; fake.cd = 40; assert(E:Evaluate("lowHealth", 1) == false) end),
T("low health: one defensive ready is enough", function()
  fake.hp.player = 20; fake.cd = {[871] = 300, [12975] = 0}; assert(E:Evaluate("lowHealth", 1) == true) end),
T("low health: hidden when no checked defensive is known", function()
  fake.hp.player = 20; fake.known = false; assert(E:Evaluate("lowHealth", 1) == false) end),
T("low health: unreadable cooldown counts as not ready", function()
  fake.hp.player = 20; fake.cd = {}; assert(E:Evaluate("lowHealth", 1) == false) end),
T("low health: HealthPct nil keeps hidden, no error", function()
  fake.hp.player = nil; assert(E:Evaluate("lowHealth", 1) == false) end),
T("interrupt: target casting and the spell usable", function()
  fake.usable = true; assert(E:Evaluate("interrupt", 1) == false)
  fake.casting = true; assert(E:Evaluate("interrupt", 2) == true)
  fake.usable = false; assert(E:Evaluate("interrupt", 3) == false) end),
T("interrupt: on cooldown is hidden", function()
  fake.usable = true; fake.casting = true; fake.cd = 8; assert(E:Evaluate("interrupt", 1) == false) end),
T("shield block: needs a shield, combat, off cooldown", function()
  fake.usable = true; fake.stance = 2; assert(E:Evaluate("shieldBlock", 1) == true)
  fake.shield = false; assert(E:Evaluate("shieldBlock", 2) == false); fake.shield = true
  fake.combat = false; assert(E:Evaluate("shieldBlock", 3) == false); fake.combat = true
  fake.cd = 3; assert(E:Evaluate("shieldBlock", 4) == false) end),
T("debuff: shows stacks and time left on the target", function()
  assert(E:Evaluate("sunder", 1) == false); fake.debuff = {stacks = 3, expires = 40}
  local s, i = E:Evaluate("sunder", 10); assert(s == true and i.stacks == 3 and i.remaining == 30) end),
T("combatOnly setting hides an alert out of combat", function()
  fake.usable = true; fake.combat = false; DB:Alert("execute").combatOnly = true
  assert(E:Evaluate("execute", 1) == false); fake.combat = true; assert(E:Evaluate("execute", 2) == true) end),
T("Test mode shows every enabled alert and nothing disabled", function()
  fake.known = false; DB:Alert("rend").enabled = false; E:Test(true)
  for _, d in ipairs(ns.Data.ALERTS) do
    local s, i = E:Evaluate(d.key, 3); assert(s == (d.key ~= "rend"), d.key)
    if s then assert(i.duration == 10 and i.remaining > 0 and i.remaining <= 10, d.key) end
  end
  E:Test(false); assert(E:Evaluate("execute", 3) == false) end),
T("subscribers are told only on change", function()
  local calls = {}; E:Subscribe(function(key, shown) if key == "execute" then calls[#calls + 1] = shown end end)
  fake.usable = true; E:Tick(1); E:Tick(2); fake.usable = false; E:Tick(3); E:Tick(4)
  assert(#calls == 2 and calls[1] == true and calls[2] == false, #calls) end),
T("subscribers hear about a stack change while shown", function()
  local n = 0; E:Subscribe(function(key) if key == "sunder" then n = n + 1 end end)
  fake.debuff = {stacks = 1, expires = 40}; E:Tick(1); fake.debuff = {stacks = 2, expires = 45}; E:Tick(2); E:Tick(3)
  assert(n == 2, n) end),
T("a failing subscriber does not stop the others", function()
  local got; E:Subscribe(function() error("boom") end); E:Subscribe(function(key) if key == "execute" then got = true end end)
  fake.usable = true; E:Tick(1); assert(got) end),
}
