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
{"every role and every text of the page exists", function()
  local ns = load(false)
  for _, role in ipairs(ns.Consumables.ROLES) do assert(rawget(ns.L, "CONS_ROLE_" .. role), role) end
  for _, k in ipairs({"OPT_CONSUMABLES", "CONS_SUBTITLE", "CONS_DISCLAIMER"}) do assert(rawget(ns.L, k), k) end end},
}
