local ADDON, ns = ...

-- Rageborn: helpers for values the client may hide ("secret") and for plain tables.
local U = {}
ns.U = U

function U.IsSecret(v)
    return issecretvalue ~= nil and issecretvalue(v) or false
end

-- v, or nil when the client hides it. Everything read from the game passes through here
-- before it is compared or used in arithmetic.
function U.Clean(v)
    if U.IsSecret(v) then return nil end
    return v
end

local function cleanAll(ok, ...)
    if not ok then return end
    local n = select("#", ...)
    if n == 0 then return end
    local r = { ... }
    for i = 1, n do
        if U.IsSecret(r[i]) then r[i] = nil end
    end
    return unpack(r, 1, n)
end

-- Calls fn safely: nothing on error, secret results turned into nil.
function U.Call(fn, ...)
    if type(fn) ~= "function" then return end
    return cleanAll(pcall(fn, ...))
end

-- Classic Era (and Hardcore, which is the same client) rather than Forever: the game's own
-- project constant says so. Era lacks Forever's talents and has the Classic durations.
ns.ERA = WOW_PROJECT_CLASSIC ~= nil and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

-- The version from the TOC. A version with "beta" in it is a test version: the addon then says
-- so in its window and once at login, and stops by itself when the version no longer does.
ns.VERSION = U.Call(C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata, ADDON, "Version") or ""
ns.BETA = ns.VERSION:lower():find("beta", 1, true) ~= nil

-- A spell's name and icon, with the calls each client has.
function U.SpellName(id)
    if not id then return nil end
    return U.Call(C_Spell and C_Spell.GetSpellName, id) or (U.Call(GetSpellInfo, id))
end
function U.SpellTexture(id)
    if not id then return nil end
    return U.Call(C_Spell and C_Spell.GetSpellTexture, id) or U.Call(GetSpellTexture, id)
end

function U.DeepCopy(t)
    if type(t) ~= "table" then return t end
    local c = {}
    for k, v in pairs(t) do c[k] = U.DeepCopy(v) end
    return c
end

-- Fills what dst lacks from defaults; never overwrites a value the player already has.
function U.DeepMerge(dst, defaults)
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            U.DeepMerge(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end
