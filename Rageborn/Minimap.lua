local ADDON, ns = ...

-- Rageborn: our own button on the minimap. Left click opens the settings, right click
-- toggles test mode; dragging moves it around the minimap's edge. Its place (an angle in
-- degrees, 0 = east, counter-clockwise) and whether it is hidden are saved per profile.
local L, U = ns.L, ns.U

local Button = {}
ns.Minimap = Button

local EDGE = 5      -- how far outside the minimap's edge the button's centre sits
local button

--- Where the button's centre is from the minimap's centre.
function Button.Position(angle, radius)
    local a = math.rad(angle)
    return math.cos(a) * radius, math.sin(a) * radius
end

--- The angle of a point (dx, dy) from the minimap's centre, 0 to 360.
function Button.Angle(dx, dy)
    return math.deg(math.atan2(dy, dx)) % 360
end

local function setting() return ns.DB:Profile().minimap end

-- Re-reads the setting: shown or hidden, and where.
function Button:Apply()
    if not button then return end
    local opt = setting()
    button:SetShown(not opt.hide)
    local x, y = Button.Position(tonumber(opt.angle) or 200, (U.Call(Minimap.GetWidth, Minimap) or 140) / 2 + EDGE)
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- While dragged: the button sits on the edge, towards the mouse.
local function follow()
    local mx, my = U.Call(Minimap.GetCenter, Minimap)
    local cx, cy = U.Call(GetCursorPosition)
    local scale = U.Call(Minimap.GetEffectiveScale, Minimap)
    if not (mx and my and cx and cy and scale) or scale == 0 then return end
    setting().angle = Button.Angle(cx / scale - mx, cy / scale - my)
    Button:Apply()
end

local function tooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine(L.ADDON_NAME)
    GameTooltip:AddLine(L.MINIMAP_LEFT, 1, 1, 1)
    GameTooltip:AddLine(L.MINIMAP_RIGHT, 1, 1, 1)
    GameTooltip:AddLine(L.MINIMAP_DRAG, 1, 1, 1)
    GameTooltip:Show()
end

function Button:Start()
    if button or not Minimap then return end
    button = CreateFrame("Button", nil, Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    -- the ring, its dark centre and the highlight are the game's own minimap-button art
    local back = button:CreateTexture(nil, "BACKGROUND")
    back:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    back:SetSize(24, 24)
    back:SetPoint("CENTER", button, "CENTER", 0, 0)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\Rageborn\\Media\\icon")
    icon:SetSize(18, 18)
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    local ring = button:CreateTexture(nil, "OVERLAY")
    ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    ring:SetSize(ns.ERA and 53 or 50, ns.ERA and 53 or 50)     -- Era draws the ring a little larger
    ring:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnClick", function(_, which)
        if which == "RightButton" then
            ns.testing = not ns.testing
            ns.Engine:Test(ns.testing)
        else
            ns.Options:Toggle()
        end
    end)
    button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", follow) end)
    button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    button:SetScript("OnEnter", tooltip)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    ns.DB:OnChange(function() Button:Apply() end)
    self:Apply()
end
