local ADDON, ns = ...

-- Rageborn: start-up. Modules are optional here so the addon loads while it is being built.
local L = ns.L
local isWarrior = select(2, UnitClass("player")) == "WARRIOR"

local function say(text) print("|cffc69b6dRageborn|r: " .. text) end
ns.Say = say

local COMMANDS = {
    test = function() if ns.Engine then ns.testing = not ns.testing; ns.Engine:Test(ns.testing) end end,
    move = function() if ns.Mover then ns.Mover:Toggle(not ns.Mover:IsOn()) end end,
    reset = function() if ns.DB then ns.DB:Reset() end end,
}

SLASH_RAGEBORN1, SLASH_RAGEBORN2 = "/rb", "/rageborn"
SlashCmdList.RAGEBORN = function(msg)
    if not isWarrior then say(L.NOT_A_WARRIOR) return end
    local cmd = COMMANDS[(msg or ""):lower():match("^%s*(%S*)")]
    if cmd then cmd() elseif ns.Options then ns.Options:Toggle() end
end

function Rageborn_OnCompartmentClick()
    SlashCmdList.RAGEBORN("")
end

if not isWarrior then return end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name ~= ADDON then return end
        if ns.DB then ns.DB:Init(UnitName("player") .. "-" .. GetRealmName()) end
    else
        for _, key in ipairs({ "Engine", "Alerts", "Bars", "Glow" }) do
            if ns[key] and ns[key].Start then ns[key]:Start() end
        end
    end
end)
