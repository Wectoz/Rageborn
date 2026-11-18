local ADDON, ns = ...

-- Rageborn: the glow on action buttons. While an alert is up, every button that casts its
-- spell carries one of our own frames: a child of the button, never Blizzard's glow (calling
-- that on an action button taints it).
--   glow   one frame per button, made once and kept
--   part   the textures and animation of one style on that frame (textures can't be
--          destroyed, so a style the player switches away from is hidden and kept)
local U, Data = ns.U, ns.Data

local Glow = {}
ns.Glow = Glow

Glow.STYLES = { "procLoop", "ants", "pulse", "corners" }

local TEX = "Interface\\AddOns\\Rageborn\\Media\\Textures\\"

local glows = {}        -- button -> { frame, parts by style, part and asked: the style in use }
local up = {}           -- alert key -> the spells to press, for the alerts that are up
local lit = {}          -- the buttons the alerts light now
local waiting = false   -- a frame could not be made during the fight

-- One of the game's two glow flipbooks. Both are 30 pictures in 6 rows of 5 and loop in a
-- second (Blizzard's ActionButtonSpellAlertTemplate and
-- ActionBarButtonAssistedCombatHighlightTemplate). Gray, so the tint is the colour chosen.
local function flipbook(f, group, atlas)
    local tex = f:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints(f)
    tex:SetAtlas(atlas)
    tex:SetDesaturated(true)
    group:SetLooping("REPEAT")
    local a = group:CreateAnimation("FlipBook")
    a:SetTarget(tex)
    a:SetFlipBookRows(6)
    a:SetFlipBookColumns(5)
    a:SetFlipBookFrames(30)
    a:SetFlipBookFrameWidth(0)
    a:SetFlipBookFrameHeight(0)
    a:SetDuration(1)
    return { tex }
end

-- The corner of the glow frame each bracket sits in, and how the art (drawn for the top
-- left) is mirrored for it. Texture coordinates past 1 leave the bracket short of the
-- middle of the side.
local CORNERS = {
    { "TOPLEFT", "BOTTOMRIGHT", 0, 1.4, 0, 1.4 },
    { "TOPRIGHT", "BOTTOMLEFT", 1.4, 0, 0, 1.4 },
    { "BOTTOMLEFT", "TOPRIGHT", 0, 1.4, 1.4, 0 },
    { "BOTTOMRIGHT", "TOPLEFT", 1.4, 0, 1.4, 0 },
}

-- size: the glow frame against the button. build(frame, group) -> its textures.
local LOOK = {
    procLoop = { size = 1.4, atlas = "UI-HUD-ActionBar-Proc-Loop-Flipbook" },
    ants = { size = 66 / 45, atlas = "rotationhelper_ants_flipbook" },
    -- a square frame breathing
    pulse = { size = 1.25, build = function(f, group)
        local tex = f:CreateTexture(nil, "OVERLAY")
        tex:SetAllPoints(f)
        tex:SetTexture(TEX .. "frame")
        group:SetLooping("BOUNCE")
        local a = group:CreateAnimation("Alpha")
        a:SetTarget(tex)
        a:SetFromAlpha(1)
        a:SetToAlpha(0.3)
        a:SetDuration(0.6)
        return { tex }
    end },
    -- four brackets turning around the button's centre
    corners = { size = 1.13, build = function(f, group)
        local list = {}
        group:SetLooping("REPEAT")
        for i, c in ipairs(CORNERS) do
            local tex = f:CreateTexture(nil, "OVERLAY")
            tex:SetTexture(TEX .. "corner")
            tex:SetTexCoord(c[3], c[4], c[5], c[6])
            tex:SetPoint(c[1], f, c[1], 0, 0)
            tex:SetPoint(c[2], f, "CENTER", 0, 0)
            local a = group:CreateAnimation("Rotation")
            a:SetTarget(tex)
            a:SetOrigin(c[2], 0, 0)
            a:SetDegrees(-360)
            a:SetDuration(6)
            list[i] = tex
        end
        return list
    end },
}

-- The style to draw: the first one for a name we don't have, "pulse" when the client lacks
-- the flipbook.
local function resolve(style)
    if not LOOK[style] then style = Glow.STYLES[1] end
    local atlas = LOOK[style].atlas
    if atlas and not U.Call(C_Texture and C_Texture.GetAtlasInfo, atlas) then style = "pulse" end
    return style
end

local function glowFor(button)
    local glow = glows[button]
    if glow then return glow end
    -- nothing is made on a protected button during a fight: its glow starts after it
    if InCombatLockdown() and U.Call(button.IsProtected, button) ~= false then
        waiting = true
        return nil
    end
    local f = CreateFrame("Frame", nil, button)
    f:SetPoint("CENTER", button, "CENTER", 0, 0)
    f:SetFrameLevel((U.Call(button.GetFrameLevel, button) or 0) + 5)
    f:Hide()
    glow = { frame = f, parts = {} }
    glows[button] = glow
    return glow
end

local function play(part, on)
    for _, tex in ipairs(part.textures) do tex:SetShown(on) end
    if on then part.group:Play() else part.group:Stop() end
end

function Glow:Show(button, style, r, g, b)
    local glow = glowFor(button)
    if not glow then return end
    local f = glow.frame
    local changed = glow.asked ~= style
    if changed then
        if glow.part then play(glow.part, false) end
        glow.asked = style
        local key = resolve(style)
        local look = LOOK[key]
        f:SetSize((U.Call(button.GetWidth, button) or 36) * look.size, (U.Call(button.GetHeight, button) or 36) * look.size)
        if not glow.parts[key] then
            local group = f:CreateAnimationGroup()
            local textures = look.atlas and flipbook(f, group, look.atlas) or look.build(f, group)
            glow.parts[key] = { textures = textures, group = group }
        end
        glow.part = glow.parts[key]
    end
    for _, tex in ipairs(glow.part.textures) do tex:SetVertexColor(r, g, b) end
    if changed or not f:IsShown() then
        f:Show()
        play(glow.part, true)
    end
end

function Glow:Hide(button)
    local glow = glows[button]
    if not glow then return end
    if glow.part then glow.part.group:Stop() end
    glow.frame:Hide()
end

-- Lights the buttons of the alerts that are up and puts out the others. When two alerts
-- share a button, the first in Data.ALERTS gives the look.
local function evaluate()
    local want = {}
    for _, def in ipairs(Data.ALERTS) do
        local opt = up[def.key] and ns.DB:Alert(def.key)
        if opt and opt.glow then
            for _, id in ipairs(up[def.key]) do
                for _, button in ipairs(ns.Bars:ButtonsFor(id)) do want[button] = want[button] or opt end
            end
        end
    end
    for button in pairs(lit) do
        if not want[button] then
            lit[button] = nil
            Glow:Hide(button)
        end
    end
    for button, opt in pairs(want) do
        lit[button] = true
        local c = opt.glowColor
        Glow:Show(button, opt.glowStyle, c.r, c.g, c.b)
    end
end

-- Out of combat, makes the frame of every button an alert could light, so a proc in a fight
-- finds it ready.
local function prepare()
    for _, def in ipairs(Data.ALERTS) do
        for _, id in ipairs(def.spells or {}) do
            for _, button in ipairs(ns.Bars:ButtonsFor(id)) do glowFor(button) end
        end
    end
end

-- The engine's news about one alert. The spell to glow is the one the engine names (the rank
-- known, the defensive that is ready), unless the alert lists its own in `press`.
function Glow:OnAlert(key, shown, info)
    local def = Data.BY_KEY[key]
    up[key] = shown and def and (def.press or { info and info.spellID }) or nil
    evaluate()
end

function Glow:Start()
    ns.Engine:Subscribe(function(key, shown, info) Glow:OnAlert(key, shown, info) end)
    ns.Bars:OnRescan(function() prepare(); evaluate() end)
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:SetScript("OnEvent", function()
        if waiting then
            waiting = false
            evaluate()
        end
    end)
    prepare()
end
