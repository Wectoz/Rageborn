local ADDON, ns = ...

-- Rageborn: everything read from the game. Each function returns plain values or nil:
-- never a secret value, never an error. In combat the client hides some answers; nil means
-- "can't tell right now", and the engine keeps its last answer.
-- Written against the calls other Forever addons use; docs/probe-results.md confirms them.
local U = ns.U
local Call, Clean = U.Call, U.Clean

local Detect = {}
ns.Detect = Detect

local GCD = 1.5

function Detect.IsKnown(spellID)
    return Call(IsPlayerSpell, spellID) == true or Call(IsSpellKnown, spellID) == true
end

-- usable, lacksRage. usable nil = unreadable.
function Detect.Usable(spellID)
    local usable, noPower = Call(C_Spell and C_Spell.IsSpellUsable, spellID)
    if type(usable) ~= "boolean" then return nil, nil end
    return usable, noPower == true
end

-- Seconds until the spell is off cooldown; 0 when ready (the global cooldown counts as ready).
function Detect.CooldownLeft(spellID)
    local info = Call(C_Spell and C_Spell.GetSpellCooldown, spellID)
    if type(info) ~= "table" then return nil end
    local start, duration = Clean(info.startTime), Clean(info.duration)
    if type(start) ~= "number" or type(duration) ~= "number" then return nil end
    if duration <= GCD then return 0 end
    return math.max(0, start + duration - GetTime())
end

-- Health in percent. Raw health is hidden in combat; the percent on a 0-100 scale is not.
function Detect.HealthPct(unit)
    if Call(UnitExists, unit) ~= true then return nil end
    local hp, max = Call(UnitHealth, unit), Call(UnitHealthMax, unit)
    if type(hp) == "number" and type(max) == "number" and max > 0 then return hp / max * 100 end
    local scale = CurveConstants and CurveConstants.ScaleTo100
    if UnitHealthPercent and scale then
        local pct = Call(UnitHealthPercent, unit, false, scale)
        if type(pct) == "number" then return pct end
    end
    return nil
end

-- expirationTime, duration of the first of these buffs on the player.
function Detect.PlayerBuff(spellIDs)
    local get = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
    for _, id in ipairs(spellIDs) do
        local aura = Call(get, id)
        if type(aura) == "table" then
            local expires, duration = Clean(aura.expirationTime), Clean(aura.duration)
            if type(expires) == "number" then return expires, duration end
        end
    end
    return nil
end

-- stacks, expirationTime of the first of these debuffs on the target.
function Detect.TargetDebuff(spellIDs)
    local get = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
    local want = {}
    for _, id in ipairs(spellIDs) do want[id] = true end
    for i = 1, 40 do
        local aura = Call(get, "target", i, "HARMFUL")
        if type(aura) ~= "table" then return nil end
        local id = Clean(aura.spellId)
        if id and want[id] then
            local stacks, expires = Clean(aura.applications), Clean(aura.expirationTime)
            return type(stacks) == "number" and stacks or 0, type(expires) == "number" and expires or nil
        end
    end
    return nil
end

function Detect.Stance()
    local form = Call(GetShapeshiftForm)
    if form == 1 or form == 2 or form == 3 then return form end
    return nil
end

function Detect.TargetCasting()
    return Call(UnitCastingInfo, "target") ~= nil or Call(UnitChannelInfo, "target") ~= nil
end

function Detect.HasShield()
    local item = Call(GetInventoryItemID, "player", 17)
    if not item then return false end
    local _, _, _, equipLoc = Call(C_Item and C_Item.GetItemInfoInstant, item)
    return equipLoc == "INVTYPE_SHIELD"
end

-- What is wrong with the player now, as a set: the game's loss-of-control kinds (STUN, ROOT,
-- FEAR, CHARM, SILENCE ...), SNARE when you run slower than normal, POISON and DISEASE from
-- your debuffs. Whatever can't be read is simply absent.
function Detect.Afflictions()
    local set = {}
    local LoC = C_LossOfControl
    for i = 1, Call(LoC and LoC.GetActiveLossOfControlDataCount) or 0 do
        local data = Call(LoC.GetActiveLossOfControlData, i)
        local kind = type(data) == "table" and Clean(data.locType)
        if type(kind) == "string" then set[kind == "STUN_MECHANIC" and "STUN" or kind] = true end
    end
    local _, run = Call(GetUnitSpeed, "player")
    if type(run) == "number" and run > 0 and run < (BASE_MOVEMENT_SPEED or 7) then set.SNARE = true end
    local get = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
    for i = 1, 40 do
        local aura = Call(get, "player", i, "HARMFUL")
        if type(aura) ~= "table" then break end
        local kind = Clean(aura.dispelName)
        if kind == "Poison" or kind == "Disease" then set[kind:upper()] = true end
    end
    return set
end

-- Enemies in combat near you, counted from their nameplates; nil when that can't be read.
-- Counts only what has a nameplate on screen, whoever it is fighting.
function Detect.Enemies()
    local plates = Call(C_NamePlate and C_NamePlate.GetNamePlates)
    if type(plates) ~= "table" then return nil end
    local n = 0
    for _, plate in ipairs(plates) do
        local unit = type(plate) == "table" and Clean(plate.namePlateUnitToken)
        if unit and Call(UnitCanAttack, "player", unit) == true and Call(UnitAffectingCombat, unit) == true
            and Call(UnitIsDead, unit) ~= true then
            n = n + 1
        end
    end
    return n
end

function Detect.IsQueued(spellID)
    return Call(C_Spell and C_Spell.IsCurrentSpell, spellID) == true
end

function Detect.InCombat()
    return Call(InCombatLockdown) == true or Call(UnitAffectingCombat, "player") == true
end

-- Resting, mounted or dead: no reminders
function Detect.Quiet()
    return Call(IsResting) == true or Call(IsMounted) == true or Call(UnitIsDeadOrGhost, "player") == true
end
