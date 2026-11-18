-- Rageborn probe: throwaway. Prints, for each thing Rageborn wants to read, whether the
-- client gives a plain value, a secret one, nil, or an error. /rbprobe runs it by hand;
-- it also runs by itself 1 s after you enter combat.
local ART_IDS = { 424570,449486,449487,449488,449489,449490,449491,449492,449493,449494,450913,450914,450915,450916,450917,450918,450919,450920,450921,450922,450923,450924,450925,450926,450927,450928,450929,450930,450931,450932,450933,457658,458740,458741,459313,459314,460830,460831,461878,463452,467696,469752,510822,510823,511104,511105,511469,592058,603338,603339,623950,623951,623952,627609,627610,656728,774420,801266,801267,801268,898423,962497,1001511,1001512,1027131,1027132,1027133,1028091,1028092,1028136,1028137,1028138,1028139,1029138,1029139,1029140,1030393,1057288,1518303,2851787,2851788,2888300 }
local ATLASES = { "UI-HUD-ActionBar-Proc-Loop-Flipbook", "rotationhelper_ants_flipbook" }
local SPELLS = { 7384, 6572, 5308, 402927 }

local function isSecret(v) return issecretvalue ~= nil and issecretvalue(v) or false end

local function class(v)
    if isSecret(v) then return "secret" end
    if v == nil then return "nil" end
    return "plain " .. tostring(v)
end

local function log(line)
    RagebornProbeDB = RagebornProbeDB or { log = {} }
    local where = InCombatLockdown() and "[combat] " or "[calm] "
    table.insert(RagebornProbeDB.log, where .. line)
    print("|cffff8040rbprobe|r " .. where .. line)
end

-- name: classified results of fn(...), or the error
local function check(name, fn, ...)
    if type(fn) ~= "function" then log(name .. ": missing function") return end
    local function pack(...) return select("#", ...), { ... } end
    local n, r = pack(pcall(fn, ...))   -- n counts trailing nils too
    if not r[1] then log(name .. ": error " .. tostring(r[2])) return end
    local out = {}
    for i = 2, math.max(2, n) do out[#out + 1] = class(r[i]) end
    log(name .. ": " .. table.concat(out, " | "))
end

-- a field of a table result
local function field(name, fn, key, ...)
    if type(fn) ~= "function" then log(name .. ": missing function") return end
    local ok, t = pcall(fn, ...)
    if not ok then log(name .. ": error " .. tostring(t)) return end
    if isSecret(t) then log(name .. ": secret (whole table)") return end
    if type(t) ~= "table" then log(name .. ": " .. class(t)) return end
    local ok2, v = pcall(function() return t[key] end)
    log(name .. "." .. key .. ": " .. (ok2 and class(v) or ("error " .. tostring(v))))
end

local function run()
    local scale = CurveConstants and CurveConstants.ScaleTo100
    log("--- run, CurveConstants.ScaleTo100 " .. (scale and "exists" or "MISSING"))
    for _, unit in ipairs({ "player", "target" }) do
        check("UnitHealth " .. unit, UnitHealth, unit)
        check("UnitHealthMax " .. unit, UnitHealthMax, unit)
        check("UnitHealthPercent " .. unit, UnitHealthPercent, unit, false, scale)
    end
    for _, id in ipairs(SPELLS) do
        check("IsSpellUsable " .. id, C_Spell and C_Spell.IsSpellUsable, id)
        field("GetSpellCooldown " .. id, C_Spell and C_Spell.GetSpellCooldown, "startTime", id)
        field("GetSpellCooldown " .. id, C_Spell and C_Spell.GetSpellCooldown, "duration", id)
    end
    check("IsCurrentSpell 78", C_Spell and C_Spell.IsCurrentSpell, 78)
    field("PlayerAura 6673", C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID, "expirationTime", 6673)
    for _, key in ipairs({ "spellId", "applications", "expirationTime" }) do
        field("TargetHarmful 1", C_UnitAuras and C_UnitAuras.GetAuraDataByIndex, key, "target", 1, "HARMFUL")
    end
    check("UnitCastingInfo target", UnitCastingInfo, "target")
    check("GetShapeshiftForm", GetShapeshiftForm)
end

local function atLogin()
    for _, atlas in ipairs(ATLASES) do
        field("atlas " .. atlas, C_Texture and C_Texture.GetAtlasInfo, "width", atlas)
    end
    local f = CreateFrame("Frame"); f:Hide()
    local t, found, missing = f:CreateTexture(), 0, {}
    for _, id in ipairs(ART_IDS) do
        local ok, res = pcall(t.SetTexture, t, id)
        if ok and res ~= false then found = found + 1 else missing[#missing + 1] = id end
        t:SetTexture(nil)
    end
    log(("overlay art: %d of %d load; missing: %s"):format(found, #ART_IDS, table.concat(missing, ",")))
end

local frame = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "PLAYER_REGEN_DISABLED", "PARTY_KILL", "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" }) do
    pcall(frame.RegisterEvent, frame, e)
end
pcall(frame.RegisterUnitEvent, frame, "UNIT_SPELLCAST_SUCCEEDED", "player")
pcall(frame.RegisterUnitEvent, frame, "UNIT_COMBAT", "player", "target")
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        RagebornProbeDB = { log = {} }
        atLogin()
    elseif event == "PLAYER_REGEN_DISABLED" then
        C_Timer.After(1, run)
    else
        local out = {}
        for i = 1, select("#", ...) do out[i] = class((select(i, ...))) end
        log("event " .. event .. ": " .. table.concat(out, " | "))
    end
end)

SLASH_RBPROBE1 = "/rbprobe"
SlashCmdList.RBPROBE = run
