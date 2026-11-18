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
