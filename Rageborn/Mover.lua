local ADDON, ns = ...

-- Rageborn: move mode. Every enabled alert is shown (the engine's test mode) with a labelled
-- handle to drag; dropping saves the alert's position as an offset from the screen centre.
-- Screen-edge alerts have no position and get no handle.
local L = ns.L

local Mover = {}
ns.Mover = Mover

local HANDLE_W, HANDLE_H = 130, 20
local on, startedTest = false, false
local handles, watcher = {}, nil

local function movable(key)
    local opt = ns.DB:Alert(key)
    return opt.enabled and opt.onScreen ~= false and ns.Styles.Resolve(opt.style) ~= "vignette"
end

-- Puts every handle on its alert. Alerts that share a position get their handles stacked,
-- so each can be grabbed; h.dy is how far a handle sits under its alert's position.
local function place()
    local taken = {}
    for _, def in ipairs(ns.Data.ALERTS) do
        local h, opt = handles[def.key], ns.DB:Alert(def.key)
        if h then
            h:SetShown(on and movable(def.key))
            if h:IsShown() then
                local at = opt.x .. ":" .. opt.y
                h.dy = (taken[at] or 0) * (HANDLE_H + 2)
                taken[at] = (taken[at] or 0) + 1
                h:ClearAllPoints()
                h:SetPoint("CENTER", UIParent, "CENTER", opt.x, opt.y - h.dy)
            end
        end
    end
end

-- Saves where the handle is as the alert's position.
local function save(h)
    local x, y = h:GetCenter()
    if not x then return end
    local opt = ns.DB:Alert(h.key)
    opt.x = math.floor(x - UIParent:GetWidth() / 2 + 0.5)
    opt.y = math.floor(y - UIParent:GetHeight() / 2 + h.dy + 0.5)
    ns.Alerts:Apply(h.key)
end

local function handle(key)
    local h = CreateFrame("Frame", nil, UIParent)
    h.key, h.dy = key, 0
    h:SetSize(HANDLE_W, HANDLE_H)
    h:SetFrameStrata("HIGH")
    h:SetClampedToScreen(true)
    h:SetMovable(true)
    h:EnableMouse(true)
    h:RegisterForDrag("LeftButton")
    local bg = h:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(h)
    bg:SetColorTexture(0, 0, 0, 0.75)
    local text = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("CENTER", h, "CENTER", 0, 0)
    text:SetText(ns.Alerts:Name(key))
    h:SetScript("OnDragStart", function(self)
        self:StartMoving()
        self:SetScript("OnUpdate", save)       -- the alert follows the handle
    end)
    h:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self:SetScript("OnUpdate", nil)
        save(self)
        place()
    end)
    return h
end

function Mover:IsOn() return on end

function Mover:Toggle(want)
    want = want and true or false
    if want == on then return end
    on = want
    if on then
        if not watcher then
            watcher = CreateFrame("Frame")
            watcher:RegisterEvent("PLAYER_REGEN_DISABLED")
            watcher:SetScript("OnEvent", function() Mover:Toggle(false) end)
            ns.DB:OnChange(place)
        end
        for _, def in ipairs(ns.Data.ALERTS) do
            handles[def.key] = handles[def.key] or handle(def.key)
        end
        startedTest = not ns.Engine:IsTesting()
        if startedTest then ns.Engine:Test(true) end
    elseif startedTest then
        ns.Engine:Test(false)
    end
    place()
    ns.Say(on and L.MOVE_ON or L.MOVE_OFF)
end

function Mover:ResetPosition(key)
    local opt, def = ns.DB:Alert(key), ns.DB.Defaults().alerts[key]
    if not opt then return end
    opt.x, opt.y = def.x, def.y
    ns.Alerts:Apply(key)
    place()
end
