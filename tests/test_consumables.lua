-- The consumables lists: one per client, well formed, and never mixed up.
local function load(era)
  WOW_PROJECT_CLASSIC, WOW_PROJECT_ID = 2, era and 2 or 18
  local ns = Stub.load("Util.lua", {}); Stub.load("Locale.lua", ns); Stub.load("Consumables.lua", ns)
  WOW_PROJECT_CLASSIC, WOW_PROJECT_ID = nil, nil
  return ns
end
local function each(ns, fn)
  for _, role in ipairs(ns.Consumables.ROLES) do
    local sections = ns.Consumables.List(role); assert(#sections == 6, role)
    for _, section in ipairs(sections) do
      assert(rawget(ns.L, "CONS_SEC_" .. section[1]), section[1]); assert(#section[2] > 0, role .. " " .. section[1])
      local seen = {}
      for _, row in ipairs(section[2]) do
        local id = row[1] or row.spell
        assert(type(id) == "number" and not seen[id], role .. " " .. section[1] .. " " .. tostring(id)); seen[id] = true
        if row[1] then assert(type(row[2]) == "string" and type(row[3]) == "string" and not row[3]:match("^CONS_"), id) end
        if row.prof then assert(rawget(ns.L, "PROF_" .. row.prof), row.prof) end
        if row.spell then assert(row.prof == "enchanting" and type(row.skill) == "number" and #row.mats > 0, id) end
        for _, m in ipairs(row.mats or {}) do
          assert(type(m[1]) == "number" and m[2] >= 1 and type(m[3]) == "string" and m[3] ~= "?", id)
        end
        for _, k in ipairs({"extra", "from"}) do assert(row[k] == nil or not row[k]:match("^CONS_"), id) end
        fn(row, section[1])
      end
    end
  end
end
return {
{"Era lists hold only items the Era client has: no Forever items, Classic names", function()
  local ns, names = load(true), {}
  each(ns, function(row) if row[1] then assert(row[1] < 200000, row[1]); names[row[2]] = true end end)
  assert(names["Elixir of Giants"] and names["Juju Power"] and not names["Elixir of the Grizzly"]) end},
{"Forever lists use Forever's items and names", function()
  local ns, names = load(false), {}
  each(ns, function(row) if row[1] then names[row[2]] = true end end)
  assert(names["Elixir of the Grizzly"] and names["Elixir of Greater Strength"] and names["Major Frenzy Potion"])
  assert(not names["Elixir of Giants"] and not names["Juju Power"]) end},
{"crafted items say who makes them, at what skill, from what", function()
  local F, E = load(false).Consumables.LISTS.forever.dps, load(true).Consumables.LISTS.era.dps
  local function find(list, id) for _, s in ipairs(list) do for _, r in ipairs(s[2]) do if r[1] == id then return r end end end end
  local grizzly, titans, roids = find(F, 250351), find(E, 13510), find(E, 8410)
  assert(grizzly.prof == "alchemy" and grizzly.skill == 300 and #grizzly.mats == 3)
  assert(titans.skill == 300 and titans.extra and titans.mats[1][2] == 30)         -- 30 Gromsblood
  assert(roids.prof == nil and roids.from and find(F, 8410).from:find("unconfirmed"))    -- Forever: Classic source, not confirmed
  assert(grizzly.from:find("240") and find(F, 13510).extra == nil) end},
{"every role and every text of the page exists", function()
  local ns = load(false)
  for _, role in ipairs(ns.Consumables.ROLES) do assert(rawget(ns.L, "CONS_ROLE_" .. role), role) end
  for _, k in ipairs({"OPT_CONSUMABLES", "CONS_SUBTITLE", "CONS_DISCLAIMER", "CONS_STACK_forever", "CONS_STACK_era"}) do assert(rawget(ns.L, k), k) end end},
}
