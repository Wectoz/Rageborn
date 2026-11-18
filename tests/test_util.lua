local ns = Stub.load("Util.lua", {})
local U = ns.U
return {
{"Clean passes plain values", function() assert(U.Clean(5) == 5); assert(U.Clean(false) == false) end},
{"Clean hides secrets", function() assert(U.Clean(Stub.secret()) == nil) end},
{"IsSecret is false when the client has no issecretvalue", function()
  local keep = issecretvalue; issecretvalue = nil
  local r = U.IsSecret(5); issecretvalue = keep; assert(r == false) end},
{"Call swallows errors", function() assert(select("#", U.Call(function() error("x") end)) == 0) end},
{"Call replaces secret returns", function()
  local a, b = U.Call(function() return 1, Stub.secret() end); assert(a == 1 and b == nil) end},
{"Call keeps a nil in the middle", function()
  local a, b, c = U.Call(function() return 1, nil, 3 end); assert(a == 1 and b == nil and c == 3) end},
{"Call with something that is not a function returns nothing", function()
  assert(select("#", U.Call(nil, 1)) == 0) end},
{"DeepMerge fills missing, keeps existing", function()
  local d = U.DeepMerge({a = 1, t = {x = 9}}, {a = 2, b = 3, t = {x = 1, y = 2}})
  assert(d.a == 1 and d.b == 3 and d.t.x == 9 and d.t.y == 2) end},
{"DeepMerge keeps an existing false", function()
  assert(U.DeepMerge({on = false}, {on = true}).on == false) end},
{"DeepMerge repairs a wrong type", function()
  assert(U.DeepMerge({t = 5}, {t = {y = 2}}).t.y == 2) end},
{"DeepMerge does not share default tables", function()
  local def = {t = {y = 2}}; local d = U.DeepMerge({}, def); d.t.y = 7; assert(def.t.y == 2) end},
{"DeepCopy copies nested tables", function()
  local a = {t = {1}}; local b = U.DeepCopy(a); b.t[1] = 2; assert(a.t[1] == 1) end},
}
