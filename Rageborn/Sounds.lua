local ADDON, ns = ...

-- Rageborn: the alert sounds. Game sounds only (by sound-kit ID), never sound files.
local L = ns.L

local Sounds = {}
ns.Sounds = Sounds

-- SOUNDKIT name where the client has one, else the number.
local function kit(name, id) return SOUNDKIT and SOUNDKIT[name] or id end

Sounds.LIST = {
    { key = "none",          label = L.SOUND_NONE },
    { key = "raidWarning",   label = L.SOUND_RAID_WARNING,   kit = kit("RAID_WARNING", 8959) },
    { key = "readyCheck",    label = L.SOUND_READY_CHECK,    kit = kit("READY_CHECK", 8960) },
    { key = "levelUp",       label = L.SOUND_LEVEL_UP,       kit = kit("LEVELUP", 888) },
    { key = "pvpFlag",       label = L.SOUND_PVP_FLAG,       kit = kit("PVP_THROUGH_QUEUE", 8459) },
    { key = "auctionClose",  label = L.SOUND_AUCTION_CLOSE,  kit = kit("AUCTION_WINDOW_CLOSE", 5275) },
    { key = "mapPing",       label = L.SOUND_MAP_PING,       kit = kit("MAP_PING", 3175) },
    { key = "questComplete", label = L.SOUND_QUEST_COMPLETE, kit = kit("IG_QUEST_LIST_COMPLETE", 878) },
    { key = "tell",          label = L.SOUND_TELL,           kit = kit("TELL_MESSAGE", 3081) },
    { key = "alarm",         label = L.SOUND_ALARM,          kit = kit("ALARM_CLOCK_WARNING_1", 18871) },
    { key = "bell",          label = L.SOUND_BELL,           kit = 6594 },
}

local byKey = {}
for _, s in ipairs(Sounds.LIST) do byKey[s.key] = s end

function Sounds.Play(key)
    local s = byKey[key]
    if s and s.kit and PlaySound then pcall(PlaySound, s.kit, "Master") end
end
