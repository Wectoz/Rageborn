local ADDON, ns = ...

-- Rageborn: which action buttons cast which spell. Buttons are found by name (one pattern
-- per bar addon) and read when the bars change, never per frame.
local U = ns.U

local Bars = {}
ns.Bars = Bars

-- { addon, button name, buttons [, bars] }. A bar addon that isn't installed has no such
-- globals and costs a few failed lookups; a new bar addon is one new line.
Bars.PATTERNS = {
    { "Blizzard", "ActionButton%d", 12 },
    { "Blizzard", "MultiBarBottomLeftButton%d", 12 },
    { "Blizzard", "MultiBarBottomRightButton%d", 12 },
    { "Blizzard", "MultiBarRightButton%d", 12 },
    { "Blizzard", "MultiBarLeftButton%d", 12 },
    { "Blizzard", "MultiBar5Button%d", 12 },
    { "Blizzard", "MultiBar6Button%d", 12 },
    { "Blizzard", "MultiBar7Button%d", 12 },
    { "EllesmereUIActionBars", "EABButton%d", 180 },     -- named after the action slot
    { "Dominos", "DominosActionButton%d", 180 },
    { "Bartender4", "BT4Button%d", 180 },
    { "ElvUI", "ElvUI_Bar%dButton%d", 12, 15 },
}

local found = {}            -- { button, spell = name shown, macro = { [name] = true } }
local listeners = {}
local pending, queued = false, false

local CASTS = { ["/cast"] = true, ["/use"] = true, ["/castsequence"] = true }

-- ASCII letters to lower case; other bytes (accented letters) are left as they are.
local function lower(s) return (s:gsub("%u", string.lower)) end

-- The spell names a macro can cast, lower-cased, in order, each once.
-- Handles [conditions], alternatives split by ";", "(Rank N)", the "!" prefix and
-- /castsequence lists with their reset= part. Slot numbers ("/use 13") are not spells.
function Bars.MacroSpells(body)
    local found, seen = {}, {}
    if type(body) ~= "string" then return found end
    local function add(name)
        name = name:gsub("%b[]", "")            -- any conditions
        name = name:gsub("%(.-%)%s*$", "")      -- (Rank 3)
        name = name:match("^%s*!?%s*(.-)%s*$")  -- "!" toggle prefix, outer spaces
        if name == "" or name:match("^%d+$") or lower(name) == "null" then return end
        name = lower(name)
        if not seen[name] then seen[name] = true; found[#found + 1] = name end
    end
    for line in body:gmatch("[^\r\n]+") do
        local cmd, rest = line:match("^%s*(/%a+)%s*(.*)$")
        cmd = cmd and lower(cmd)
        if CASTS[cmd] then
            for part in rest:gmatch("[^;]+") do
                if cmd == "/castsequence" then
                    part = part:gsub("%b[]", ""):gsub("reset=%S+", "")
                    for name in part:gmatch("[^,]+") do add(name) end
                else
                    add(part)
                end
            end
        end
    end
    return found
end

----------------------------------------------------------------------
-- Reading the bars
----------------------------------------------------------------------
local function spellName(id)
    local name = U.SpellName(id)
    return type(name) == "string" and lower(name) or nil
end

-- The action slot a button shows now: Blizzard's template (EllesmereUI and Dominos use it)
-- keeps it in .action, LibActionButton (Bartender4, ElvUI) in ._state_action.
local function slotOf(button)
    local slot = U.Clean(button.action)
    if type(slot) ~= "number" then slot = U.Clean(button._state_action) end
    if type(slot) ~= "number" then slot = tonumber((U.Call(button.GetAttribute, button, "action"))) end
    return slot
end

-- The spell a slot shows, and for a macro the set of spells its text names.
local function read(slot)
    local kind, id, subType = U.Call(GetActionInfo, slot)
    if kind == "spell" then return spellName(id) end
    if kind ~= "macro" then return nil end
    -- A macro that shows a spell is reported as that spell, not as the macro: the macro is
    -- then found by the name on the button.
    local macro, shown = id, nil
    if subType == "spell" then
        macro, shown = U.Call(GetActionText, slot), id
    else
        shown = U.Call(GetMacroSpell, id)
    end
    local names = {}
    for _, name in ipairs(Bars.MacroSpells((U.Call(GetMacroBody, macro)))) do names[name] = true end
    return spellName(shown), names
end

local function scan()
    found = {}
    for _, p in ipairs(Bars.PATTERNS) do
        for bar = 1, p[4] or 1 do
            for i = 1, p[3] do
                local button = _G[p[4] and p[2]:format(bar, i) or p[2]:format(i)]
                local slot = type(button) == "table" and slotOf(button)
                if slot then
                    local spell, macro = read(slot)
                    if spell or macro then found[#found + 1] = { button = button, spell = spell, macro = macro } end
                end
            end
        end
    end
end

-- The buttons that cast the spell: matched by name, so any rank on the bar counts.
function Bars:ButtonsFor(spellID)
    local list, name = {}, spellName(spellID)
    if not name then return list end
    local every = ns.DB:Profile().glowEveryMacroSpell
    for _, e in ipairs(found) do
        if e.spell == name or (every and e.macro and e.macro[name]) then list[#list + 1] = e.button end
    end
    return list
end

function Bars:OnRescan(fn) listeners[#listeners + 1] = fn end

-- In combat the scan waits for the end of the fight.
function Bars:Rescan()
    if InCombatLockdown() then pending = true; return end
    pending = false
    scan()
    for _, fn in ipairs(listeners) do fn() end
end

function Bars:Start()
    local frame = CreateFrame("Frame")
    for _, event in ipairs({ "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD", "ACTIONBAR_SLOT_CHANGED", "UPDATE_MACROS",
                             "ACTIONBAR_PAGE_CHANGED", "UPDATE_BONUS_ACTIONBAR", "SPELLS_CHANGED" }) do
        pcall(frame.RegisterEvent, frame, event)
    end
    frame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" then
            if pending then Bars:Rescan() end
        elseif not queued then          -- these come in bursts: one scan for all of them
            queued = true
            C_Timer.After(0.2, function() queued = false; Bars:Rescan() end)
        end
    end)
    Bars:Rescan()
end
