local ADDON, ns = ...

-- Rageborn: which action buttons cast which spell (button discovery comes with Glow).
local Bars = {}
ns.Bars = Bars

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
