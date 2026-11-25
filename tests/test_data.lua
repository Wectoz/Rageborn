local ns = Stub.load("Util.lua", {})
Stub.load("Data.lua", ns)
local Data = ns.Data
local function set(...) local s = {}; for _, v in ipairs({...}) do s[v] = true end; return s end
local KINDS = set("usable", "reminder", "active", "lowHealth", "debuff", "buff")
local GROUPS = set("procs", "reminders", "defensives", "offensives", "lowHealth", "target")
local STYLES = set("gameArt", "arcs", "frame", "ring", "vignette", "bar")
return {
{"there are alerts", function() assert(#Data.ALERTS >= 22, #Data.ALERTS) end},
{"keys are unique and BY_KEY matches", function()
  local seen = {}
  for _, d in ipairs(Data.ALERTS) do
    assert(type(d.key) == "string" and not seen[d.key], tostring(d.key)); seen[d.key] = true
    assert(Data.BY_KEY[d.key] == d)
  end end},
{"every alert has a valid kind, group and default style", function()
  for _, d in ipairs(Data.ALERTS) do
    assert(KINDS[d.kind], d.key .. " kind"); assert(GROUPS[d.group], d.key .. " group")
    assert(STYLES[d.defaultStyle], d.key .. " style"); assert(type(d.defaultOn) == "boolean", d.key .. " defaultOn")
  end end},
{"every group in GROUPS is valid and every alert's group is listed", function()
  local listed = {}
  for _, g in ipairs(Data.GROUPS) do assert(GROUPS[g], g); listed[g] = true end
  for _, d in ipairs(Data.ALERTS) do assert(listed[d.group], d.key) end end},
{"every non-lowHealth alert lists spells", function()
  for _, d in ipairs(Data.ALERTS) do
    if d.kind ~= "lowHealth" then assert(type(d.spells) == "table" and #d.spells > 0, d.key) end
  end end},
{"active alerts and battle shout have a duration", function()
  for _, d in ipairs(Data.ALERTS) do
    if (d.kind == "active" and d.proc ~= "queued") or d.key == "battleShout" then
      assert(type(d.duration) == "number" and d.duration > 0, d.key) end
  end end},
{"spec defaults: which alerts start on", function()
  local on = set("overpower", "revenge", "execute", "victoryRush", "interrupt", "battleShout",
                 "shieldWall", "lastStand", "recklessness", "deathWish", "lowHealth", "goreDrinker", "enrage", "demoPull", "racial", "fearBreak")
  for _, d in ipairs(Data.ALERTS) do assert(d.defaultOn == (on[d.key] or false), d.key) end end},
{"spec values", function()
  assert(Data.BY_KEY.battleShout.defaultThreshold == 3); assert(Data.BY_KEY.lowHealth.defaultThreshold == 35)
  assert(Data.BY_KEY.overpower.window == 5 and Data.BY_KEY.victoryRush.window == 20)
  assert(Data.BY_KEY.overpower.procBuff[1] == 1289681) end},
{"every client's TOC loads the same files; Era gets the Classic durations and keeps both Enrage sets", function()
  local function files(toc)
    local list = {}
    for line in io.lines("Rageborn/" .. toc) do if line:match("%.lua$") then list[#list + 1] = line end end
    return table.concat(list, " ")
  end
  local base = files("Rageborn.toc")
  assert(#base > 100 and files("Rageborn_Camelot.toc") == base and files("Rageborn_Vanilla.toc") == base)
  assert(Data.BY_KEY.battleShout.duration == 180 and Data.BY_KEY.shieldWall.duration == 12)
  WOW_PROJECT_CLASSIC, WOW_PROJECT_ID = 2, 2
  local era = Stub.load("Util.lua", {}); Stub.load("Locale.lua", era); Stub.load("Data.lua", era)
  WOW_PROJECT_CLASSIC, WOW_PROJECT_ID = nil, nil
  local E = era.Data.BY_KEY
  assert(era.ERA == true and E.battleShout.duration == 120 and E.shieldWall.duration == 10)
  assert(E.shieldBlockUp.duration == 5 and E.demoPull.recast == 30 and #E.enrage.buffs == 5)
  local known = { [13048] = true, [20600] = true, [12975] = true }       -- an Era human with Enrage rank 5
  local function has(key) return era.Data.Known(E[key], function(id) return known[id] end) ~= nil end
  assert(has("enrage") and has("lastStand") and not has("goreDrinker") and not has("racial") and not has("victoryRush")) end},
{"Known returns the highest known rank", function()
  local known = {[7384] = true, [7887] = true}
  assert(Data.Known(Data.BY_KEY.overpower, function(id) return known[id] end) == 7887) end},
{"Known returns nil when nothing is learned", function()
  assert(Data.Known(Data.BY_KEY.overpower, function() return false end) == nil) end},
{"Known survives isKnown returning nil or a secret", function()
  assert(Data.Known(Data.BY_KEY.overpower, function() return nil end) == nil)
  assert(Data.Known(Data.BY_KEY.overpower, function() return Stub.secret() end) == nil) end},
{"Known is nil for an alert without spells", function()
  assert(Data.Known(Data.BY_KEY.lowHealth, function() return true end) == nil) end},
}
