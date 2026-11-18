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
return {
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
