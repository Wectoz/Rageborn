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

-- A widget that accepts any call and remembers the last arguments of each; Create* calls
-- return another one. A test can set a field (w.GetCenter = function ...) to answer a call.
function Stub.widget()
    local w = { calls = {}, scripts = {}, shown = true }
    return setmetatable(w, { __index = function(_, method)
        return function(self, ...)
            w.calls[method] = { ... }
            if method == "GetFont" then return "Fonts\\FRIZQT__.TTF", 12, "" end
            if method == "Show" then w.shown = true elseif method == "Hide" then w.shown = false end
            if method == "SetShown" then w.shown = ... and true or false end
            if method == "IsVisible" or method == "IsShown" then return w.shown end
            if method == "GetFrameStrata" then return "MEDIUM" end
            if method == "SetTexture" then return true end
            if method == "SetScript" then local name, fn = ...; w.scripts[name] = fn end
            if method:match("^Create") then return Stub.widget() end
        end
    end })
end
