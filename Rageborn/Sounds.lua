local ADDON, ns = ...

-- Rageborn: the sounds. Game sounds only (by sound-kit ID), never sound files.
--   each alert has its own sound, played when it appears (Alerts.lua)
--   the profile has one crit sound, and one switch that silences everything
local U, L = ns.U, ns.L

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

-- Spell sounds of every class, later expansions included: { class, name, sound kit, name, sound kit, ... }. Kit IDs are
-- from the Classic Era sound tables (build 1.15.9); a kit this client lacks is simply silent.
local CLASS_SOUNDS = {
    { "WARRIOR", "Battle Shout", 3113, "Execute", 3133, "Thunder Clap", 3090, "Rend", 3134, "Taunt", 3216, "Challenging Shout", 3222, "Cleave", 3112, "Shield Wall", 3094, "Recklessness", 3071, "Whirlwind", 5674, "Shockwave", 12981, "Devastate", 14663, "Heroic Throw", 15230 },
    { "MAGE", "Fireball", 1507, "Frost Nova", 3076, "Arcane Explosion", 6539, "Polymorph", 1372, "Counterspell", 3227, "Teleport", 3226, "Arcane Missiles", 3333, "Cone of Cold", 5594, "Hot Streak", 12977, "Deep Freeze", 12879, "Arcane Barrage", 12975, "Living Bomb", 12978 },
    { "PALADIN", "Divine Shield", 15, "Lay on Hands", 1431, "Holy Light", 1430, "Seal of Might", 1455, "Exorcism", 3320, "Devotion Aura", 1505, "Shield of the Righteous", 15307 },
    { "PRIEST", "Flash Heal", 1434, "Renew", 3155, "Shadow Word: Pain", 3085, "Inner Fire", 3314, "Resurrection", 37, "Shadowform", 5756, "Prayer of Healing", 1508, "Guardian Spirit", 13876, "Mind Sear", 15007 },
    { "ROGUE", "Stealth", 3325, "Vanish", 3324, "Eviscerate", 3264, "Gouge", 3313, "Kidney Shot", 3323, "Sinister Strike", 5530, "Cold Blood", 6774 },
    { "HUNTER", "Aspect of the Hawk", 5496, "Aspect of the Cheetah", 6478, "Aspect of the Monkey", 5318, "Flare", 2549, "Call Pet", 3980, "Tame Beast", 3351, "Chimera Shot", 13159, "Explosive Shot", 13590 },
    { "DRUID", "Rejuvenation", 3229, "Moonfire", 5734, "Starfire", 5895, "Entangling Roots", 2579, "Thorns", 3225, "Swipe", 3223, "Challenging Roar", 3326, "Faerie Fire", 2615, "Eclipse", 12984, "Starfall", 12988, "Nourish", 12990, "Berserk", 13263, "Feral Charge", 13351, "Savage Roar", 13797 },
    { "SHAMAN", "Lightning Bolt", 1490, "Call Lightning", 30, "Lightning Shield", 33, "Rockbiter", 3620, "Purge", 3316, "Fire Nova", 5636, "Ghost Wolf", 3089, "Astral Recall", 3315, "Thunderstorm", 13006, "Lava Burst", 13039 },
    { "WARLOCK", "Fear", 3231, "Immolate", 38, "Soulstone", 7354, "Curse", 5694, "Death Coil", 743, "Demon Armor", 1365, "Infernal", 7315, "Metamorphosis", 13874 },
    { "DEATHKNIGHT", "Death Strike", 13243, "Howling Blast", 13167, "Death and Decay", 13104, "Hysteria", 12998, "Anti-Magic Zone", 13004 },
}
for _, row in ipairs(CLASS_SOUNDS) do
    for i = 2, #row, 2 do
        Sounds.LIST[#Sounds.LIST + 1] = { key = "kit" .. row[i + 1], kit = row[i + 1], class = row[1],
                                          label = L["CLASS_" .. row[1]] .. ": " .. row[i] }
    end
end

local byKey = {}
for _, s in ipairs(Sounds.LIST) do byKey[s.key] = s end

-- force: play even when the player turned sounds off (trying one out in the settings).
function Sounds.Play(key, force)
    local s = byKey[key]
    if not (s and s.kit and PlaySound) then return end
    if not force and ns.DB and ns.DB:Profile().sounds == false then return end
    pcall(PlaySound, s.kit, "Master")
end

-- The sound whose key or label the player typed, whatever the capitals.
function Sounds.Find(text)
    text = (text or ""):lower()
    for _, s in ipairs(Sounds.LIST) do
        if s.key:lower() == text or s.label:lower() == text then return s end
    end
end

-- A critical hit on your target. The combat log is closed to addons, so this is read from
-- UNIT_COMBAT, which doesn't say who hit.
-- shortcut: in a group other players' crits on your target count too; upgrade if the
-- client ever tells an addon who dealt the hit.
local CRIT_GAP = 0.3       -- one sound for hits that land together (Cleave, Whirlwind)
local lastCrit = -1
function Sounds.OnCombat(unit, action, flag, now)
    if unit ~= "target" or action ~= "WOUND" or flag ~= "CRITICAL" then return end
    if now - lastCrit < CRIT_GAP then return end
    lastCrit = now
    Sounds.Play(ns.DB:Profile().critSound)
end

function Sounds:Start()
    local frame = CreateFrame("Frame")
    pcall(frame.RegisterUnitEvent, frame, "UNIT_COMBAT", "target")
    frame:SetScript("OnEvent", function(_, _, unit, action, flag)
        Sounds.OnCombat(U.Clean(unit), U.Clean(action), U.Clean(flag), GetTime())
    end)
end
