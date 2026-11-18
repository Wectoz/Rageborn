-- Minimal fake of the WoW client for tests run with the system lua5.1.
Stub = { now = 0 }

local SECRET = setmetatable({}, { __tostring = function() return "<secret>" end })
function Stub.secret() return SECRET end
issecretvalue = function(v) return v == SECRET end
GetTime = function() return Stub.now end

-- Runs Rageborn/<file> the way the client does: with the addon name and the shared table.
function Stub.load(file, ns)
    local chunk = assert(loadfile("Rageborn/" .. file))
    chunk("Rageborn", ns)
    return ns
end
