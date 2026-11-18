-- A fake of the bars: named buttons, what their slots hold, the macros.
local inCombat, timers, events, slots, macros = false, {}, nil, {}, {}
local NAMES = { [7384] = "Overpower", [11585] = "Overpower", [6572] = "Revenge", [772] = "Rend" }
InCombatLockdown = function() return inCombat end
C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
C_Spell = { GetSpellName = function(id) return NAMES[id] end }
CreateFrame = function() events = Stub.widget(); return events end
GetActionInfo = function(slot) local s = slots[slot]; if s then return s[1], s[2], s[3] end end
GetActionText = function(slot) return slots[slot] and slots[slot].text end
GetMacroSpell = function(macro) return macros[macro] and macros[macro].spell end
GetMacroBody = function(macro) return macros[macro] and macros[macro].body end
local function button(name, slot) local b = Stub.widget(); b.action = slot; _G[name] = b; return b end
local b1, b2, b3, b4 = button("ActionButton1", 1), button("EABButton62", 62), button("MultiBarLeftButton3", 3),
                       button("ElvUI_Bar2Button4", 4)
local lab = Stub.widget(); lab._state_action = 5; BT4Button5 = lab       -- LibActionButton keeps the slot elsewhere
local attr = Stub.widget(); attr.GetAttribute = function() return "6" end; DominosActionButton6 = attr
DominosActionButton7 = Stub.widget()                                      -- a button with no slot

local ns = Stub.load("Util.lua", {})
Stub.load("Bars.lua", ns)
local Bars = ns.Bars
local profile = { glowEveryMacroSpell = false }
ns.DB = { Profile = function() return profile end }
local scans = 0
Bars:OnRescan(function() scans = scans + 1 end)
local function fire(event) events.scripts.OnEvent(events, event) end
local function runTimers() local t = timers; timers = {}; for _, fn in ipairs(t) do fn() end end
local function fresh(s, m) slots, macros, inCombat, profile.glowEveryMacroSpell = s, m or {}, false, false; Bars:Rescan() end
local function same(list, ...)
  local want = {...}
  assert(#list == #want, #list .. " buttons")
  for i = 1, #want do assert(list[i] == want[i], "button " .. i) end
end
local function eq(body, ...)
  local got, want = Bars.MacroSpells(body), {...}
  assert(#got == #want, "got: " .. table.concat(got, "|"))
  for i = 1, #want do assert(got[i] == want[i], "got: " .. table.concat(got, "|")) end
end
return {
{"plain cast", function() eq("/cast Overpower", "overpower") end},
{"use and ranks", function() eq("/use Execute(Rank 3)", "execute") end},
{"conditions and alternatives", function()
  eq("/cast [stance:1] Overpower; [stance:2] Revenge", "overpower", "revenge") end},
{"several condition blocks before one spell", function()
  eq("/cast [@mouseover,harm][@target] Taunt", "taunt") end},
{"showtooltip and blank lines are ignored", function() eq("#showtooltip Charge\n\n/cast Charge", "charge") end},
{"castsequence with reset", function()
  eq("/castsequence reset=target/6 Rend, Overpower, null", "rend", "overpower") end},
{"castsequence with a condition before reset", function()
  eq("/castsequence [combat] reset=10 Rend, Hamstring", "rend", "hamstring") end},
{"bang prefix and trailing semicolon", function() eq("/cast !Heroic Strike;", "heroic strike") end},
{"slot numbers and items by slot are skipped", function() eq("/use 13\n/cast Bloodrage", "bloodrage") end},
{"other slash commands are ignored", function() eq("/startattack\n/equip Sword\n/cast Rend", "rend") end},
{"upper-case commands and Windows line ends", function() eq("/CAST Rend\r\n/Use Cleave\r\n", "rend", "cleave") end},
{"non-ASCII names survive", function() eq("/cast Überwältigen", "Überwältigen") end},
{"nil, empty and non-string bodies", function() eq(nil); eq(""); eq(42) end},
{"no duplicates", function() eq("/cast Rend\n/cast [mod] Rend", "rend") end},
{"an empty alternative is skipped", function() eq("/cast [mod] ; Rend", "rend") end},
{"a spell on the bar is found by name, whatever its rank and whatever the bar addon", function()
  fresh({ [1] = {"spell", 7384}, [62] = {"spell", 11585}, [3] = {"spell", 772}, [4] = {"item", 7384},
          [5] = {"spell", 7384}, [6] = {"spell", 7384} })
  same(Bars:ButtonsFor(11585), b1, b2, attr, lab); same(Bars:ButtonsFor(772), b3)
  same(Bars:ButtonsFor(6572)); same(Bars:ButtonsFor(99999)); same(Bars:ButtonsFor(nil)) end},
{"a macro counts for the spell it shows; for every spell it names only when the setting is on", function()
  fresh({ [1] = {"macro", 7384, "spell", text = "Dance"}, [62] = {"macro", 9}, [3] = {"macro", 10} },
        { Dance = { body = "/cast [stance:1] Overpower; Revenge" }, [9] = { spell = 6572, body = "/cast Revenge\n/cast Rend" },
          [10] = {} })
  same(Bars:ButtonsFor(7384), b1); same(Bars:ButtonsFor(6572), b2); same(Bars:ButtonsFor(772))
  profile.glowEveryMacroSpell = true
  same(Bars:ButtonsFor(6572), b1, b2); same(Bars:ButtonsFor(772), b2) end},
{"a secret slot, action or macro text is skipped without an error", function()
  local S = Stub.secret(); b1.action = S
  fresh({ [62] = {"spell", S}, [3] = {"macro", 7384, "spell", text = S}, [4] = {S, 7384} }, {})
  b1.action = 1
  same(Bars:ButtonsFor(7384), b3) end},
{"Rescan in combat is deferred", function()   -- Review Focus 5
  fresh({}); Bars:Start(); scans = 0
  inCombat = true; Bars:Rescan(); assert(scans == 0)
  inCombat = false; fire("PLAYER_REGEN_ENABLED"); assert(scans == 1)
  fire("PLAYER_REGEN_ENABLED"); assert(scans == 1) end},
{"a burst of bar events makes one scan", function()
  scans = 0; fire("ACTIONBAR_SLOT_CHANGED"); fire("UPDATE_MACROS"); fire("ACTIONBAR_SLOT_CHANGED")
  assert(scans == 0 and #timers == 1); runTimers(); assert(scans == 1)
  fire("SPELLS_CHANGED"); runTimers(); assert(scans == 2) end},
}
