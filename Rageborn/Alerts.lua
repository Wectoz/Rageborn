local ADDON, ns = ...

-- Rageborn: the alerts on screen. The engine says which alerts are up; this draws them in
-- the style the player chose and animates them from one OnUpdate.
--   frame  one per alert, carries position, size and opacity
--   body   one per style the alert has used (textures can't be destroyed, so a style
--          the player switches away from is hidden and kept); carries the pop on show
local U, Data, Styles = ns.U, ns.Data, ns.Styles

local Alerts = {}
ns.Alerts = Alerts

local POP, FADE, BREATH = 0.15, 0.2, 1.6
local STANCE_SPELL = { 2457, 71, 2458 }     -- battle, defensive, berserker
local NO_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local alerts, previews = {}, {}

local function spellIcon(id)
    return id and U.Call(C_Spell and C_Spell.GetSpellTexture, id) or NO_ICON
end

local function highestSpell(key)
    local spells = Data.BY_KEY[key].spells
    return spells and spells[#spells]
end

local function new(key, parent, preview)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(Styles.BASE_W, Styles.BASE_H)
    frame:Hide()
    return { key = key, frame = frame, bodies = {}, preview = preview }
end

-- Re-reads the alert's settings.
local function apply(a)
    local opt = ns.DB:Alert(a.key)
    if not opt then return end
    local f = a.frame
    local styleKey = Styles.Resolve(opt.style)
    local b = a.bodies[styleKey]
    if not b then
        local body = CreateFrame("Frame", nil, f)
        body:SetSize(Styles.BASE_W, Styles.BASE_H)
        body:SetPoint("CENTER", f, "CENTER", 0, 0)
        local style = Styles.Get(styleKey).build(body, { key = a.key, icon = spellIcon(highestSpell(a.key)) })
        if a.preview and style.host then          -- a full-screen style stays inside its preview
            style.host:SetAllPoints(f)
            style.host:SetFrameStrata(f:GetFrameStrata())
        end
        b = { body = body, style = style }
        a.bodies[styleKey] = b
    end
    for _, other in pairs(a.bodies) do other.body:SetShown(other == b) end
    a.body, a.style, a.opacity = b.body, b.style, opt.opacity or 1

    if not a.preview then
        local scale = math.max(0.1, (opt.size or 1) * (ns.DB:Profile().scale or 1))
        f:SetScale(scale)
        f:ClearAllPoints()
        f:SetPoint("CENTER", UIParent, "CENTER", (opt.x or 0) / scale, (opt.y or 0) / scale)
    end
    local s, c = a.style, opt.color
    Styles.Call(s, "SetColor", c.r, c.g, c.b, opt.recolor)
    Styles.Call(s, "SetSpread", opt.spread)
    Styles.Call(s, "SetSides", opt.side)
    Styles.Call(s, "SetPart", "icon", opt.showIcon)
    Styles.Call(s, "SetPart", "name", opt.showName)
    Styles.Call(s, "SetPart", "timer", opt.showTimer)
    a.shownInfo = nil       -- the style may be new: show the info again
end

-- What changes only when the engine says so: icon, name, stacks, stance hint.
local function showInfo(a, info)
    if a.shownInfo == info then return end
    a.shownInfo = info
    local s = a.style
    Styles.Call(s, "SetIcon", spellIcon(info.spellID))
    Styles.Call(s, "SetName", info.spellID and U.Call(C_Spell and C_Spell.GetSpellName, info.spellID) or "")
    Styles.Call(s, "SetStacks", info.stacks)
    Styles.Call(s, "SetHint", info.hintStance and spellIcon(STANCE_SPELL[info.hintStance]) or nil)
end

-- One frame of an alert. Returns false once it has faded out.
local function draw(a, info, now, elapsed, fade)
    local t = now - a.since
    showInfo(a, info)
    Styles.Call(a.style, "SetTime", info.expires and math.max(0, info.expires - now) or nil, info.duration)
    Styles.Call(a.style, "Animate", elapsed, t)
    a.body:SetScale(t < POP and 1.3 - 0.3 * t / POP or 1)
    local alpha = a.opacity * (info.dim and 0.5 or 1) * (0.9 + 0.1 * math.sin(t * 2 * math.pi / BREATH))
    a.frame:SetAlpha(alpha * fade)
end

function Alerts:Update(now, elapsed)
    for _, a in pairs(alerts) do
        if a.info then
            local fade = 1
            if a.hiddenAt then fade = 1 - (now - a.hiddenAt) / FADE end
            if fade <= 0 then
                a.info, a.hiddenAt = nil, nil
                a.frame:Hide()
            else
                draw(a, a.info, now, elapsed, fade)
            end
        end
    end
    for _, a in ipairs(previews) do
        if a.frame:IsVisible() then
            a.since = a.since or now
            local left = 10 - (now - a.since) % 10
            a.info.expires = now + left
            draw(a, a.info, now, elapsed, 1)
        else
            a.since = nil
        end
    end
end

-- The engine's news about one alert.
function Alerts:OnAlert(key, shown, info)
    local a = alerts[key]
    if not shown then
        if a and a.info and not a.hiddenAt then a.hiddenAt = GetTime() end
        return
    end
    if not a then
        self:Frame(key)
        a = alerts[key]
    end
    if not a.info or a.hiddenAt then          -- it appears: pop, and the sound once
        a.since, a.hiddenAt = GetTime(), nil
        a.frame:Show()
        ns.Sounds.Play(ns.DB:Alert(key).sound)
    end
    a.info = info
end

-- What the player calls the alert: its spell's name, or its own text when it has no spell.
function Alerts:Name(key)
    local id = highestSpell(key)
    return id and U.Call(C_Spell and C_Spell.GetSpellName, id) or ns.L["ALERT_" .. key]
end

function Alerts:Frame(key)
    if not alerts[key] then
        alerts[key] = new(key, UIParent)
        alerts[key].frame:SetFrameStrata("MEDIUM")
        apply(alerts[key])
    end
    return alerts[key].frame
end

function Alerts:Apply(key)
    if alerts[key] then apply(alerts[key]) end
    for _, a in ipairs(previews) do
        if a.key == key then apply(a) end
    end
end

-- A second instance for the settings window: always shown, a 10 s timer running in a loop.
-- The caller places and sizes the frame.
function Alerts:Preview(key, parent)
    local a = new(key, parent, true)
    a.info = { spellID = highestSpell(key), duration = 10 }
    previews[#previews + 1] = a
    apply(a)
    a.frame:Show()
    return a.frame
end

function Alerts:Start()
    ns.Engine:Subscribe(function(key, shown, info) Alerts:OnAlert(key, shown, info) end)
    ns.DB:OnChange(function()
        for key in pairs(alerts) do Alerts:Apply(key) end
        for _, a in ipairs(previews) do apply(a) end
    end)
    local driver = CreateFrame("Frame")
    driver:SetScript("OnUpdate", function(_, elapsed) Alerts:Update(GetTime(), elapsed) end)
end
