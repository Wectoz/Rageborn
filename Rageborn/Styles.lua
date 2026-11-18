local ADDON, ns = ...

-- Rageborn: the alert styles.
--   family "shape"  drawn from our own white textures (Media\Textures), tinted in game
--   family "game"   the game's own proc overlay art, by file ID, offered only when this
--                   client has the file
--
-- A style is one builder: build(frame, ctx) -> style. frame is BASE_W x BASE_H, centred on
-- the alert. ctx = { key = alert key, icon = texture }. The style object may have:
--   SetColor(r, g, b)             required
--   SetIcon(texture)
--   SetTime(remaining, duration)  remaining nil = no timer
--   SetStacks(n)
--   SetSpread(k)                  two-sided styles: how far apart (1 = as drawn)
--   SetHint(texture | nil)        a small icon of the stance to switch to
--   SetPart(part, shown)          part = "icon" | "timer" | "name"
--   SetName(text)
--   Animate(elapsed, t)           every frame while shown; t = seconds since shown
-- Callers go through Styles.Call, so a style only implements what it draws.
-- Never ask a texture for "TRILINEAR" filtering: it crashes the Forever client.
local U, L = ns.U, ns.L

local Styles = {}
ns.Styles = Styles

local TEX = "Interface\\AddOns\\Rageborn\\Media\\Textures\\"
local BASE_W, BASE_H = 240, 200
Styles.BASE_W, Styles.BASE_H = BASE_W, BASE_H

local sin, pi = math.sin, math.pi

----------------------------------------------------------------------
-- Catalog
----------------------------------------------------------------------
local catalog, byKey = {}, {}

function Styles.Register(def)
    assert(type(def) == "table" and type(def.key) == "string", "style needs a key")
    assert(type(def.build) == "function", "style " .. def.key .. " needs a builder")
    assert(not byKey[def.key], "style " .. def.key .. " registered twice")
    catalog[#catalog + 1] = def
    byKey[def.key] = def
end

-- Whether the client has a file (remembered).
local probe, exists = nil, {}
function Styles.FileExists(file)
    if exists[file] ~= nil then return exists[file] end
    if not probe then
        probe = CreateFrame("Frame")
        probe:Hide()
        probe.t = probe:CreateTexture()
    end
    local ok, res = pcall(probe.t.SetTexture, probe.t, file)
    pcall(probe.t.SetTexture, probe.t, nil)
    exists[file] = ok and res ~= false
    return exists[file]
end

local function usable(def)
    return def ~= nil and (def.file == nil or Styles.FileExists(def.file))
end

function Styles.Get(key)
    local def = byKey[key]
    if usable(def) then return def end
    return nil
end

-- Shape styles first, then the game art this client has.
function Styles.List()
    local list = {}
    for _, family in ipairs({ "shape", "game" }) do
        for _, def in ipairs(catalog) do
            if def.family == family and usable(def) then list[#list + 1] = def end
        end
    end
    return list
end

function Styles.Resolve(key)
    if Styles.Get(key) then return key end
    return "ring"
end

function Styles.Call(style, method, ...)
    local fn = style and style[method]
    if fn then return fn(...) end
end

----------------------------------------------------------------------
-- Building blocks
----------------------------------------------------------------------
local function Tex(parent, file, w, h, layer, x, y)
    local t = parent:CreateTexture(nil, layer or "ARTWORK")
    t:SetTexture(file)
    t:SetSize(w, h)
    t:SetPoint("CENTER", parent, "CENTER", x or 0, y or 0)
    return t
end

local function Font(parent, size, x, y)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(GameFontNormal:GetFont(), size, "OUTLINE")
    fs:SetTextColor(1, 1, 1)
    fs:SetPoint("CENTER", parent, "CENTER", x or 0, y or 0)
    return fs
end

local function TimeText(rem)
    if not rem or rem <= 0 then return "" end
    if rem < 10 then return ("%.1f"):format(rem) end
    return ("%d"):format(rem + 0.5)
end
Styles.TimeText = TimeText

-- What every style shares: parts that can be hidden, the timer text, the name, the hint.
local function Base(f, ctx, o)
    local s = { parts = { icon = {}, timer = {}, name = {} } }
    if o.icon then
        local size = o.icon
        s.icon = Tex(f, ctx.icon, size, size, "ARTWORK", o.iconX, o.iconY)
        s.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        s.parts.icon[1] = s.icon
        if o.round then
            pcall(function()
                local mask = f:CreateMaskTexture()
                mask:SetTexture(TEX .. "mask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                mask:SetAllPoints(s.icon)
                s.icon:AddMaskTexture(mask)
            end)
        end
    end
    s.timer = Font(f, o.timerSize or 18, o.timerX, o.timerY or -52)
    s.parts.timer[1] = s.timer
    s.name = Font(f, 12, 0, o.nameY or -72)
    s.parts.name[1] = s.name
    s.hint = Tex(f, nil, 26, 26, "OVERLAY", o.hintX or 40, o.hintY or 40)
    s.hint:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    s.hint:Hide()

    function s.SetIcon(texture) if s.icon then s.icon:SetTexture(texture) end end
    function s.SetTime(rem) s.timer:SetText(TimeText(rem)) end
    function s.SetName(text) s.name:SetText(text or "") end
    function s.SetHint(texture)
        if texture then s.hint:SetTexture(texture) end
        s.hint:SetShown(texture ~= nil)
    end
    function s.SetPart(part, shown)
        for _, region in ipairs(s.parts[part] or {}) do region:SetShown(shown) end
    end
    return s
end

local function breathe(t, speed) return 0.5 + 0.5 * sin(t * (speed or 4)) end

----------------------------------------------------------------------
-- Shape styles
----------------------------------------------------------------------
-- Icon in a slowly turning ring, the time left swept over the icon
local function BuildRing(f, ctx)
    local s = Base(f, ctx, { icon = 64, round = true, timerY = -62, nameY = -82 })
    local glow = Tex(f, TEX .. "glow", 170, 170, "BACKGROUND"); glow:SetBlendMode("ADD")
    local ring = Tex(f, TEX .. "ring", 104, 104, "BORDER")
    local sweep = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    sweep:SetAllPoints(s.icon)
    sweep:SetDrawEdge(false)
    sweep:SetHideCountdownNumbers(true)
    pcall(sweep.SetSwipeTexture, sweep, TEX .. "mask")
    sweep:SetSwipeColor(0, 0, 0, 0.6)
    s.parts.icon[#s.parts.icon + 1] = sweep
    local shownFor
    function s.SetColor(r, g, b) ring:SetVertexColor(r, g, b); glow:SetVertexColor(r, g, b, 0.5) end
    function s.SetTime(rem, dur)
        s.timer:SetText(TimeText(rem))
        if not (rem and dur and dur > 0) then sweep:Clear(); shownFor = nil; return end
        local ends = GetTime() + rem
        if not shownFor or math.abs(shownFor - ends) > 0.3 then
            sweep:SetCooldown(ends - dur, dur); shownFor = ends
        end
    end
    function s.Animate(_, t)
        ring:SetRotation(t * 0.6)
        glow:SetAlpha(0.35 + 0.3 * breathe(t))
    end
    return s
end

-- Two arcs, left and right of the icon
local function BuildArcs(f, ctx)
    local s = Base(f, ctx, { icon = 44 })
    local left = Tex(f, TEX .. "arc", 64, 128, "ARTWORK", -70, 0)
    local right = Tex(f, TEX .. "arc", 64, 128, "ARTWORK", 70, 0)
    right:SetTexCoord(1, 0, 0, 1)
    left:SetBlendMode("ADD"); right:SetBlendMode("ADD")
    local spread = 1
    function s.SetColor(r, g, b) left:SetVertexColor(r, g, b); right:SetVertexColor(r, g, b) end
    function s.SetSpread(k)
        spread = k or 1
        left:SetPoint("CENTER", f, "CENTER", -70 * spread, 0)
        right:SetPoint("CENTER", f, "CENTER", 70 * spread, 0)
    end
    function s.Animate(_, t)
        local a = 0.65 + 0.35 * breathe(t, 5)
        left:SetAlpha(a); right:SetAlpha(a)
    end
    return s
end

-- A pulsing square frame around the icon
local function BuildFrame(f, ctx)
    local s = Base(f, ctx, { icon = 56, timerY = -50, nameY = -68 })
    local frame = Tex(f, TEX .. "frame", 84, 84, "BORDER")
    local glow = Tex(f, TEX .. "glow", 150, 150, "BACKGROUND"); glow:SetBlendMode("ADD")
    function s.SetColor(r, g, b) frame:SetVertexColor(r, g, b); glow:SetVertexColor(r, g, b) end
    function s.Animate(_, t)
        local k = breathe(t, 3.5)
        frame:SetSize(84 + 6 * k, 84 + 6 * k)
        glow:SetAlpha(0.2 + 0.35 * k)
    end
    return s
end

-- Icon with a bar that drains as the time runs out
local function BuildBar(f, ctx)
    local s = Base(f, ctx, { icon = 30, iconX = -76, timerSize = 13, timerX = 70, timerY = 0, nameY = 18,
                             hintX = -76, hintY = 30 })
    local back = Tex(f, TEX .. "bar", 128, 16, "BACKGROUND"); back:SetVertexColor(0, 0, 0, 0.6)
    local bar = CreateFrame("StatusBar", nil, f)
    bar:SetSize(124, 12)
    bar:SetPoint("CENTER", f, "CENTER", 0, 0)
    bar:SetStatusBarTexture(TEX .. "bar")
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    local stacks = Font(f, 13, -76, -24)
    function s.SetColor(r, g, b) bar:SetStatusBarColor(r, g, b) end
    function s.SetTime(rem, dur)
        s.timer:SetText(TimeText(rem))
        bar:SetValue((rem and dur and dur > 0) and math.max(0, math.min(1, rem / dur)) or 1)
    end
    function s.SetStacks(n) stacks:SetText(n and n > 0 and n or "") end
    return s
end

-- A glow along the four screen edges (low health). Ignores the alert's size and position.
local function BuildVignette(f, ctx)
    local s = Base(f, ctx, {})
    local host = CreateFrame("Frame", nil, f)
    host:SetAllPoints(UIParent)
    host:SetFrameStrata("BACKGROUND")
    local depth = 180
    local edges = {}
    local function Edge(point, w, h, l, r, t, b, quarterTurns)
        local e = host:CreateTexture(nil, "BACKGROUND")
        e:SetTexture(TEX .. "edge")
        e:SetBlendMode("ADD")
        if quarterTurns then e:SetRotation(quarterTurns * pi / 2) end
        e:SetTexCoord(l, r, t, b)
        e:SetPoint(point, host, point)
        if w then e:SetWidth(w); e:SetPoint("TOP", host, "TOP"); e:SetPoint("BOTTOM", host, "BOTTOM") end
        if h then e:SetHeight(h); e:SetPoint("LEFT", host, "LEFT"); e:SetPoint("RIGHT", host, "RIGHT") end
        edges[#edges + 1] = e
    end
    Edge("LEFT", depth, nil, 0, 1, 0, 1)
    Edge("RIGHT", depth, nil, 1, 0, 0, 1)
    -- top and bottom reuse the same gradient with swapped axes (texcoord corners)
    local top = host:CreateTexture(nil, "BACKGROUND")
    top:SetTexture(TEX .. "edge"); top:SetBlendMode("ADD")
    top:SetTexCoord(0, 0, 1, 0, 0, 1, 1, 1)
    top:SetPoint("TOPLEFT", host, "TOPLEFT"); top:SetPoint("TOPRIGHT", host, "TOPRIGHT"); top:SetHeight(depth)
    local bottom = host:CreateTexture(nil, "BACKGROUND")
    bottom:SetTexture(TEX .. "edge"); bottom:SetBlendMode("ADD")
    bottom:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)
    bottom:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT"); bottom:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT")
    bottom:SetHeight(depth)
    edges[#edges + 1], edges[#edges + 2] = top, bottom
    s.fullScreen = true
    s.host = host
    function s.SetColor(r, g, b) for _, e in ipairs(edges) do e:SetVertexColor(r, g, b) end end
    function s.Animate(_, t) host:SetAlpha(0.55 + 0.45 * breathe(t, 6)) end
    return s
end

Styles.Register({ key = "ring", family = "shape", label = L.STYLE_RING, build = BuildRing })
Styles.Register({ key = "arcs", family = "shape", label = L.STYLE_ARCS, build = BuildArcs, sides = true })
Styles.Register({ key = "frame", family = "shape", label = L.STYLE_FRAME, build = BuildFrame })
Styles.Register({ key = "bar", family = "shape", label = L.STYLE_BAR, build = BuildBar })
Styles.Register({ key = "vignette", family = "shape", label = L.STYLE_VIGNETTE, build = BuildVignette })

----------------------------------------------------------------------
-- Game art: the client's own proc overlays
----------------------------------------------------------------------
-- Art drawn once above the character; everything else is drawn on both sides, mirrored
local TOP = { [1030393] = true, [469752] = true, [449488] = true, [457658] = true }

-- "gameArt": each alert's own default overlay
local OWN_ART = { overpower = 1030393, revenge = 449494, execute = 449493, victoryRush = 469752 }
local FALLBACK_ART = 449494

local function BuildArt(file)
    return function(f, ctx)
        local s = Base(f, ctx, { icon = 40 })
        local art = {}
        if TOP[file] then
            art[1] = Tex(f, file, 256, 128, "ARTWORK", 0, 110)
        else
            art[1] = Tex(f, file, 128, 256, "ARTWORK", -150, 0)
            art[2] = Tex(f, file, 128, 256, "ARTWORK", 150, 0)
            art[2]:SetTexCoord(1, 0, 0, 1)
        end
        for _, t in ipairs(art) do t:SetBlendMode("ADD") end
        function s.SetColor(r, g, b) for _, t in ipairs(art) do t:SetVertexColor(r, g, b) end end
        function s.SetSpread(k)
            if art[2] then
                art[1]:SetPoint("CENTER", f, "CENTER", -150 * (k or 1), 0)
                art[2]:SetPoint("CENTER", f, "CENTER", 150 * (k or 1), 0)
            end
        end
        function s.Animate(_, t)
            local a = 0.7 + 0.3 * breathe(t, 3)
            for _, tex in ipairs(art) do tex:SetAlpha(a) end
        end
        return s
    end
end

Styles.Register({ key = "gameArt", family = "game", label = L.STYLE_GAME_ART, sides = true,
    build = function(f, ctx)
        local file = OWN_ART[ctx.key]
        if not (file and Styles.FileExists(file)) then file = FALLBACK_ART end
        return BuildArt(file)(f, ctx)
    end })

for _, entry in ipairs(ns.ART or {}) do
    local file, name = entry[1], entry[2]
    Styles.Register({ key = "art" .. file, family = "game", label = name, file = file,
        sides = not TOP[file], build = BuildArt(file) })
end
