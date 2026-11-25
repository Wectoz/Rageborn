local ns = Stub.load("Util.lua", {})
Stub.load("Locale.lua", ns)
local missing = {}          -- file IDs the fake client "doesn't have"
CreateFrame = function()
  local f = {}
  function f:Hide() end
  function f:CreateTexture()
    return { SetTexture = function(_, file) if missing[file] then return false end return true end }
  end
  return f
end
Stub.load("ArtList.lua", ns)
Stub.load("PaintedList.lua", ns)
missing[ns.ART[2][1]] = true
Stub.load("Styles.lua", ns)
local Styles = ns.Styles
local function tga(name)
  local f = assert(io.open("Rageborn/Media/Textures/" .. name .. ".tga", "rb"), name .. " missing")
  local d = f:read(18); f:close()
  local w, h = d:byte(13) + d:byte(14) * 256, d:byte(15) + d:byte(16) * 256
  return d:byte(3), d:byte(17), w, h
end
local function pow2(n) while n > 1 do if n % 2 ~= 0 then return false end n = n / 2 end return n == 1 end
-- A widget that accepts any method, remembers the last arguments of each, and returns
-- another such widget from Create* calls: enough to run every style builder.
local function widget()
  local w = { calls = {}, made = {} }
  return setmetatable(w, { __index = function(_, method)
    return function(self, ...)
      w.calls[method] = { ... }
      if method == "GetFont" then return "Fonts\\FRIZQT__.TTF", 12, "" end
      if method:match("^Create") then local c = widget(); w.made[#w.made + 1] = c; return c end
      if method == "SetTexture" then w.texture = ... end
    end
  end })
end
local function build(key, alertKey)
  local realCreate = CreateFrame
  CreateFrame = function() return widget() end
  UIParent, GameFontNormal = widget(), widget()
  local f = widget()
  local style = Styles.Get(key).build(f, { key = alertKey or "overpower", icon = "icon" })
  CreateFrame = realCreate
  return style, f
end
-- the art textures of a painted or game style: those whose file is not the icon
local function shownState(tex) local c = tex.calls.SetShown; return c == nil or c[1] == true end

return {
{"every style builds and runs all its methods without error", function()
  for _, d in ipairs(Styles.List()) do
    local s = build(d.key)
    assert(type(s.SetColor) == "function", d.key)
    Styles.Call(s, "SetColor", 1, 0.5, 0.2, true); Styles.Call(s, "SetColor", 1, 1, 1, false)
    Styles.Call(s, "SetIcon", "x"); Styles.Call(s, "SetTime", 4.2, 10); Styles.Call(s, "SetTime", nil, nil)
    Styles.Call(s, "SetStacks", 3); Styles.Call(s, "SetSpread", 1.4); Styles.Call(s, "SetHint", "x")
    Styles.Call(s, "SetHint", nil); Styles.Call(s, "SetName", "n"); Styles.Call(s, "Animate", 0.016, 1.5)
    for _, side in ipairs({"both", "left", "right"}) do Styles.Call(s, "SetSides", side) end
    for _, part in ipairs({"icon", "timer", "name"}) do Styles.Call(s, "SetPart", part, false) end
  end end},
{"two-sided styles can show one side only", function()
  for _, key in ipairs({"paint:overpower_side1", "arcs", "art" .. ns.ART[1][1]}) do
    local s = build(key); assert(s.left and s.right, key .. " has no left/right")
    s.SetSides("left");  assert(shownState(s.left) and not shownState(s.right), key .. " left")
    s.SetSides("right"); assert(not shownState(s.left) and shownState(s.right), key .. " right")
    s.SetSides("both");  assert(shownState(s.left) and shownState(s.right), key .. " both")
  end end},
{"painted art keeps its own colours until recoloured", function()
  local s = build("paint:overpower_side1")
  s.SetColor(0.2, 0.4, 1, false)
  assert(s.left.calls.SetDesaturated[1] == false); local c = s.left.calls.SetVertexColor
  assert(c[1] == 1 and c[2] == 1 and c[3] == 1)
  s.SetColor(0.2, 0.4, 1, true)
  assert(s.left.calls.SetDesaturated[1] == true); c = s.right.calls.SetVertexColor
  assert(c[1] == 0.2 and c[2] == 0.4 and c[3] == 1) end},
{"colour presets: at least eight, unique keys, valid colours", function()
  assert(#Styles.COLORS >= 8); local seen = {}
  for _, c in ipairs(Styles.COLORS) do
    assert(type(c.key) == "string" and not seen[c.key], tostring(c.key)); seen[c.key] = true
    for _, v in ipairs({c.r, c.g, c.b}) do assert(type(v) == "number" and v >= 0 and v <= 1, c.key) end
  end end},
{"the five shape styles are registered", function()
  for _, k in ipairs({"ring", "arcs", "frame", "bar", "vignette"}) do
    local d = Styles.Get(k); assert(d and d.family == "shape" and type(d.build) == "function", k) end end},
{"arcs has two sides, ring does not", function() assert(Styles.Get("arcs").sides == true); assert(not Styles.Get("ring").sides) end},
{"Register rejects a duplicate key", function()
  assert(not pcall(Styles.Register, {key = "ring", family = "shape", build = function() end})) end},
{"Register rejects a style without a builder", function()
  assert(not pcall(Styles.Register, {key = "nobuild", family = "shape"})) end},
{"List puts shape styles first, then game art", function()
  local seenGame = false
  for _, d in ipairs(Styles.List()) do
    if d.family == "game" then seenGame = true else assert(not seenGame, d.key .. " after game art") end
  end
  assert(seenGame) end},
{"List leaves out art the client doesn't have", function()
  local gone = "art" .. ns.ART[2][1]
  for _, d in ipairs(Styles.List()) do assert(d.key ~= gone) end
  assert(Styles.Get("art" .. ns.ART[1][1])) end},
{"gameArt is listed", function() assert(Styles.Get("gameArt").family == "game") end},
{"Resolve returns the key when it exists", function() assert(Styles.Resolve("arcs") == "arcs") end},
{"Resolve falls back to ring for an unknown key", function()
  assert(Styles.Resolve("gone") == "ring"); assert(Styles.Resolve(nil) == "ring") end},
{"Resolve falls back to ring when the art file is missing", function()
  assert(Styles.Resolve("art" .. ns.ART[2][1]) == "ring") end},
{"Call ignores a method the style lacks, and a nil style", function()
  Styles.Call({SetColor = function() end}, "SetStacks", 3); Styles.Call(nil, "SetColor", 1, 1, 1) end},
{"Call passes arguments through", function()
  local got; Styles.Call({SetStacks = function(n) got = n end}, "SetStacks", 3); assert(got == 3) end},
{"FileExists answers per file and remembers", function()
  assert(Styles.FileExists(ns.ART[1][1]) == true); assert(Styles.FileExists(ns.ART[2][1]) == false) end},
{"art list has no SpellActivationOverlay-own files", function()
  assert(#ns.ART >= 70); for _, a in ipairs(ns.ART) do assert(a[1] < 30000000 and type(a[2]) == "string") end end},
{"painted art is registered from the list", function()
  assert(#ns.PAINTED >= 21)
  for _, p in ipairs(ns.PAINTED) do
    local d = Styles.Get("paint:" .. p.file); assert(d and d.family == "painted" and d.alert == p.alert, p.file)
    assert(p.layout == "sides" or p.layout == "top" or p.layout == "emblem", p.file)
    assert(d.sides == (p.layout == "sides"), p.file)
  end end},
{"every proc alert has at least two side designs and one top design", function()
  for _, key in ipairs({"overpower", "revenge", "execute", "victoryRush", "interrupt", "battleShout", "lowHealth"}) do
    local sides, tops = 0, 0
    for _, p in ipairs(ns.PAINTED) do
      if p.alert == key and p.layout == "sides" then sides = sides + 1 end
      if p.alert == key and p.layout == "top" then tops = tops + 1 end
    end
    assert(sides >= 2 and tops >= 1, key)
  end end},
{"List for an alert: its own painted art, other painted, shapes, game art", function()
  local rank, lastRank = {own = 1, painted = 2, shape = 3, game = 4}, 0
  local own = 0
  for _, d in ipairs(Styles.List("overpower")) do
    local r = d.family == "painted" and (d.alert == "overpower" and rank.own or rank.painted) or rank[d.family]
    assert(r >= lastRank, d.key); lastRank = r
    if r == 1 then own = own + 1 end
  end
  assert(own >= 3 and lastRank == 4) end},
{"List without an alert still lists everything once", function()
  local seen = {}
  for _, d in ipairs(Styles.List()) do assert(not seen[d.key], d.key); seen[d.key] = true end
  assert(seen["paint:overpower_side1"] and seen.ring and seen.gameArt) end},
{"every design is in one menu: shapes modern, game art legacy, painted by its list entry", function()
  local n = {modern = 0, legacy = 0}
  for _, d in ipairs(Styles.List()) do
    n[d.era] = n[d.era] + 1
    if d.family == "shape" then assert(d.era == "modern", d.key) end
    if d.family == "game" then assert(d.era == "legacy", d.key) end
  end
  for _, p in ipairs(ns.PAINTED) do assert(Styles.Get("paint:" .. p.file).era == (p.legacy and "legacy" or "modern"), p.file) end
  assert(#Styles.List("overpower", "modern") == n.modern and #Styles.List("overpower", "legacy") == n.legacy)
  for _, d in ipairs(Styles.List("overpower", "legacy")) do assert(d.era == "legacy", d.key) end end},
{"DefaultFor: the alert's first side design when it has one, else the definition's style", function()
  assert(Styles.DefaultFor({key = "overpower", defaultStyle = "gameArt"}) == "paint:overpower_side1")
  assert(Styles.DefaultFor({key = "shieldWall", defaultStyle = "ring"}) == "ring") end},
{"every painted file exists as a 32-bit TGA of the listed size", function()
  for _, p in ipairs(ns.PAINTED) do
    local f = assert(io.open("Rageborn/Media/Art/" .. p.file .. ".tga", "rb"), p.file .. " missing")
    local d = f:read(18); f:close()
    local w, h = d:byte(13) + d:byte(14) * 256, d:byte(15) + d:byte(16) * 256
    assert(d:byte(3) == 2 and d:byte(17) == 32, p.file)
    local want = ({sides = {256, 512}, top = {512, 256}, emblem = {256, 256}})[p.layout]
    assert(w == want[1] and h == want[2], p.file .. " " .. w .. "x" .. h)
  end end},
{"the generator writes valid TGAs", function()
  local want = {ring = {256, 256}, arc = {128, 256}, glow = {128, 128}, frame = {128, 128}, bar = {256, 32},
    spark = {128, 128}, edge = {64, 256}, mask = {128, 128}, corner = {64, 64}, blades = {128, 128},
    shield = {128, 128}, drop = {128, 128}}
  for name, size in pairs(want) do
    local kind, bpp, w, h = tga(name)
    assert(kind == 2 and bpp == 32, name); assert(w == size[1] and h == size[2], name)
    assert(pow2(w) and pow2(h), name)
  end end},
}
