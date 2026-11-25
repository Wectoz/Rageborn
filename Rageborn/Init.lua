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
    -- /rb sounds : all sounds on or off
    sounds = function()
        local p = ns.DB:Profile()
        p.sounds = not p.sounds
        say(p.sounds and L.SOUNDS_ON or L.SOUNDS_OFF)
    end,
    -- /rb crit <sound> : the sound of a critical hit; without a sound, lists them
    crit = function(arg)
        local s = ns.Sounds.Find(arg)
        if not s then
            local keys = {}
            for _, o in ipairs(ns.Sounds.LIST) do if not o.class then keys[#keys + 1] = o.key end end   -- class sounds: in the settings
            say(L.CRIT_USAGE .. " " .. table.concat(keys, ", "))
            return
        end
        ns.DB:Profile().critSound = s.key
        ns.Sounds.Play(s.key, true)
        say(L.CRIT_SET .. " " .. s.label)
    end,
}

SLASH_RAGEBORN1, SLASH_RAGEBORN2 = "/rb", "/rageborn"
SlashCmdList.RAGEBORN = function(msg)
    if not isWarrior then say(L.NOT_A_WARRIOR) return end
    local name, arg = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
    local cmd = COMMANDS[name:lower()]
    if cmd then cmd(arg) elseif ns.Options then ns.Options:Toggle() end
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
        for _, key in ipairs({ "Engine", "Alerts", "Sounds", "Bars", "Glow", "Options", "Minimap" }) do
            if ns[key] and ns[key].Start then ns[key]:Start() end
        end
    end
end)
