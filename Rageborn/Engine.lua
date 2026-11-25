local ADDON, ns = ...

-- Rageborn: decides which alerts are up.
-- Evaluate(key, now) answers from ns.Detect (the game) and from what the engine remembers:
--   windows  a proc opened by something we saw (the target dodged, you blocked, a kill)
--   actives  a cooldown you pressed, with the time it lasts
--   shout    when Battle Shout runs out, as last read or as estimated from your own cast
-- Subscribers are told when an alert appears, disappears, or changes what it shows.
local U, Data = ns.U, ns.Data

local Engine = {}
ns.Engine = Engine

local subscribers = {}
local windows, actives, last, told, recast
local shoutExpiry      -- nil = missing
local testing = false

local EXECUTE_HEALTH = 20
local AVOID = { DODGE = true, PARRY = true, BLOCK = true }

function Engine:Reset()
    windows, actives, last, told, recast = {}, {}, {}, {}, {}
    shoutExpiry = nil
    testing = false
end
Engine:Reset()

function Engine:Subscribe(fn) subscribers[#subscribers + 1] = fn end

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------
-- The spells of an alert the character knows, highest ID first.
local function knownSpells(def)
    local list = {}
    local spells = def.spells
    if not spells then return list end
    local D = ns.Detect
    for i = #spells, 1, -1 do
        if D.IsKnown(spells[i]) == true then list[#list + 1] = spells[i] end
    end
    return list
end

local function has(list, value)
    if not list then return false end
    for _, v in ipairs(list) do if v == value then return true end end
    return false
end

local function windowLeft(key, now)
    local closes = windows[key]
    if closes and now < closes then return closes - now, closes end
    return nil
end

-- The game's answer for the alert's spells: true, false, or nil when it can't be read.
-- "Not enough rage" counts as up only while we know the proc is open (procOpen).
local function gameUsable(spells, procOpen, needReady)
    local D = ns.Detect
    local anyAnswer = false
    for _, id in ipairs(spells) do
        local usable, lacksRage = D.Usable(id)
        if usable ~= nil then anyAnswer = true end
        if usable == true or (lacksRage == true and procOpen) then
            if not needReady or D.CooldownLeft(id) == 0 then return true, id end
        end
    end
    if anyAnswer then return false end
    return nil
end

----------------------------------------------------------------------
-- One evaluator per kind. Each returns shown, info (info only when shown).
----------------------------------------------------------------------
local function evalUsable(def, opt, spells, now)
    local D = ns.Detect
    local left, closes = windowLeft(def.key, now)
    local procOpen = left ~= nil
    if def.key == "execute" then
        local hp = D.HealthPct("target")
        procOpen = hp ~= nil and hp < EXECUTE_HEALTH
    end

    if def.proc == "targetCasting" and D.TargetCasting() ~= true then return false end
    if def.needsShield and not (D.HasShield() == true and D.InCombat() == true) then return false end
    if def.needs then       -- only the spells that would help with what is wrong now
        local wrong, helps = D.Afflictions() or {}, {}
        for _, id in ipairs(spells) do
            for _, kind in ipairs(def.needs[id] or {}) do
                if wrong[kind] then helps[#helps + 1] = id; break end
            end
        end
        if #helps == 0 then return false end
        spells = helps
    end
    if def.enemies then     -- worth pressing only on a pull, and not again while it is on them
        if D.InCombat() ~= true or (D.Enemies() or 0) < (opt.threshold or 2) then return false end
        if (recast[def.key] or 0) > now or D.TargetDebuff(def.spells) then return false end
    end
    if def.rage then        -- rage to spare and no swing ability queued yet
        if D.InCombat() ~= true or (D.Rage() or 0) < (opt.threshold or 0) then return false end
        local aoe, pick = (D.Enemies() or 0) >= 2, nil
        for _, id in ipairs(spells) do              -- highest rank first within each spell
            if D.IsQueued(id) == true then return false end
            if not has(def.aoe, id) then
                pick = pick or id
            elseif aoe and not has(def.aoe, pick) then
                pick = id
            end
        end
        return pick ~= nil, { spellID = pick }
    end
    if def.lost and not (D.InCombat() == true and D.TargetLost() == true) then return false end
    local needReady = def.proc == "targetCasting" or def.needsShield or def.ready

    local usable, id = gameUsable(spells, procOpen, needReady)
    local info = { spellID = id or spells[1] }
    if left then info.remaining, info.expires, info.duration, info.estimated = left, closes, def.window, true end

    if usable == nil then usable = last[def.key] == true end   -- can't tell right now: keep
    if usable then return true, info end

    -- The proc is open but this stance can't press it: point at the stance to switch to
    if left and def.stances and opt.stanceHint and not has(def.stances, D.Stance()) then
        info.hintStance = def.stances[1]
        return true, info
    end
    return false
end

local function evalActive(def, opt, spells, now)
    if def.proc == "queued" then
        for _, id in ipairs(spells) do
            if ns.Detect.IsQueued(id) == true then return true, { spellID = id } end
        end
        return false
    end
    local a = actives[def.key]
    if a and now < a.start + a.duration then
        return true, { spellID = spells[1], remaining = a.start + a.duration - now, expires = a.start + a.duration,
                       duration = a.duration, estimated = true }
    end
    return false
end

local function evalReminder(def, opt, spells, now)
    local D = ns.Detect
    if D.Quiet() == true then return false end
    local inCombat = D.InCombat() == true
    local expires = D.PlayerBuff(def.spells)
    if expires then
        shoutExpiry = expires
    elseif not inCombat then
        shoutExpiry = nil              -- readable out of combat, so it really is gone
    end                                -- in combat an unreadable buff keeps the last answer
    local left = shoutExpiry and (shoutExpiry - now) or nil
    if left and left > (opt.threshold or 0) then return false end
    local info = { spellID = spells[1], dim = not inCombat }
    if left and left > 0 then info.remaining, info.expires, info.duration = left, shoutExpiry, def.duration end
    return true, info
end

local function evalLowHealth(def, opt)
    local D = ns.Detect
    local hp = D.HealthPct("player")
    if not hp or hp >= (opt.threshold or 0) then return false end
    for _, key in ipairs(def.defensives or {}) do
        for _, id in ipairs(knownSpells(Data.BY_KEY[key])) do
            if D.CooldownLeft(id) == 0 then return true, { spellID = id, health = hp } end
        end
    end
    return false
end

local function evalDebuff(def, opt, spells, now)
    local D = ns.Detect
    local stacks, expires = D.TargetDebuff(def.spells)
    if def.missing then     -- a reminder: only when the debuffs were read and it is not there
        if stacks ~= false or D.InCombat() ~= true or D.TargetEnemy() ~= true then return false end
        return true, { spellID = spells[1], missing = true }
    end
    if not stacks and not expires then return false end
    local info = { spellID = spells[1], stacks = stacks }
    if expires and expires > now then
        info.remaining, info.expires = expires - now, expires
        if def.defaultThreshold and info.remaining <= (opt.threshold or 0) then info.urgent = true end
    end
    return true, info
end

local EVAL = { usable = evalUsable, active = evalActive, reminder = evalReminder,
               lowHealth = evalLowHealth, debuff = evalDebuff }

function Engine:Evaluate(key, now)
    local def = Data.BY_KEY[key]
    local opt = def and ns.DB:Alert(key)
    if not opt or not opt.enabled or not ns.DB:Profile().enabled then last[key] = false; return false end
    if testing then
        local left = 10 - (now % 10)
        return true, { spellID = def.spells and def.spells[#def.spells], remaining = left, expires = now + left,
                       duration = 10, test = true }
    end
    local spells = knownSpells(def)
    if def.kind ~= "lowHealth" and #spells == 0 then last[key] = false; return false end
    if opt.combatOnly and ns.Detect.InCombat() ~= true then last[key] = false; return false end
    local shown, info = EVAL[def.kind](def, opt, spells, now)
    last[key] = shown
    if shown then return true, info end
    return false
end

----------------------------------------------------------------------
-- What the engine is told
----------------------------------------------------------------------
-- unit "player" (you were missed) or "target" (your target was missed); kind as UNIT_COMBAT gives it.
function Engine:OnMiss(unit, kind, now)
    for _, def in ipairs(Data.ALERTS) do
        if (def.proc == "targetDodge" and unit == "target" and kind == "DODGE")
            or (def.proc == "avoided" and unit == "player" and AVOID[kind]) then
            windows[def.key] = now + def.window
        end
    end
end

function Engine:OnKill(now)
    for _, def in ipairs(Data.ALERTS) do
        if def.proc == "kill" then windows[def.key] = now + def.window end
    end
end

function Engine:OnCast(spellID, now)
    if spellID == nil then return end
    for _, def in ipairs(Data.ALERTS) do
        if has(def.spells, spellID) then
            if def.window then windows[def.key] = nil end
            if def.recast then recast[def.key] = now + def.recast end
            if def.kind == "active" and def.duration then actives[def.key] = { start = now, duration = def.duration } end
            if def.kind == "reminder" then shoutExpiry = now + def.duration end
        end
    end
end

function Engine:Test(on) testing = on and true or false end
function Engine:IsTesting() return testing end

-- Evaluates every alert and tells the subscribers what changed.
function Engine:Tick(now)
    for _, def in ipairs(Data.ALERTS) do
        local key = def.key
        local shown, info = self:Evaluate(key, now)
        local sig = shown and ((info.hintStance or 0) .. ":" .. (info.stacks or 0) .. ":" .. (info.dim and 1 or 0)
            .. ":" .. (info.urgent and 1 or 0) .. ":" .. (info.spellID or 0) .. ":" .. (info.expires and math.floor(info.expires * 2) or 0)) or false
        if told[key] ~= sig then
            told[key] = sig
            for _, fn in ipairs(subscribers) do pcall(fn, key, shown, info) end
        end
    end
end

function Engine:Refresh()
    told = {}
    if GetTime then self:Tick(GetTime()) end
end

----------------------------------------------------------------------
-- Wiring to the game
----------------------------------------------------------------------
function Engine:Start()
    local frame = CreateFrame("Frame")
    local function tick() Engine:Tick(GetTime()) end
    local handlers = {
        UNIT_SPELLCAST_SUCCEEDED = function(unit, _, spellID)
            if unit == "player" then Engine:OnCast(U.Clean(spellID), GetTime()) end
        end,
        UNIT_COMBAT = function(unit, kind)
            unit, kind = U.Clean(unit), U.Clean(kind)
            if unit and kind then Engine:OnMiss(unit, kind, GetTime()) end
        end,
        PARTY_KILL = function() Engine:OnKill(GetTime()) end,
    }
    for _, event in ipairs({ "PARTY_KILL", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_TARGET_CHANGED",
                             "SPELL_UPDATE_USABLE", "SPELL_UPDATE_COOLDOWN", "UPDATE_SHAPESHIFT_FORM", "SPELLS_CHANGED" }) do
        pcall(frame.RegisterEvent, frame, event)
    end
    pcall(frame.RegisterUnitEvent, frame, "UNIT_SPELLCAST_SUCCEEDED", "player")
    pcall(frame.RegisterUnitEvent, frame, "UNIT_COMBAT", "player", "target")
    pcall(frame.RegisterUnitEvent, frame, "UNIT_AURA", "player", "target")
    frame:SetScript("OnEvent", function(_, event, ...)
        local h = handlers[event]
        if h then h(...) end
        tick()
    end)
    C_Timer.NewTicker(0.1, tick)
    ns.DB:OnChange(function() Engine:Refresh() end)
end
