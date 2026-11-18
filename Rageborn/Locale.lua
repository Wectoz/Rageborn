local ADDON, ns = ...

-- Rageborn: every text the player sees (enUS). A missing text shows its own key.
local L = setmetatable({}, { __index = function(_, k) return k end })
ns.L = L

L.ADDON_NAME = "Rageborn"
L.NOT_A_WARRIOR = "Rageborn only works on a warrior."
L.ERR_IN_COMBAT = "Not possible in combat."
L.ERR_NAME_EMPTY = "Enter a name."
L.ERR_NAME_TAKEN = "That name is already used."
L.ERR_PROFILE_IN_USE = "You can't delete the profile you are using."
L.ERR_NO_PROFILE = "That profile doesn't exist."

L.STYLE_RING = "Ring"
L.STYLE_ARCS = "Side arcs"
L.STYLE_FRAME = "Pulsing frame"
L.STYLE_BAR = "Bar"
L.STYLE_VIGNETTE = "Screen edges"
L.STYLE_GAME_ART = "Game art (this proc's own)"
