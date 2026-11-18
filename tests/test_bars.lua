local ns = Stub.load("Util.lua", {})
Stub.load("Bars.lua", ns)
local Bars = ns.Bars
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
}
