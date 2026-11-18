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

L.SOUND_NONE = "None"
L.SOUND_RAID_WARNING = "Raid warning"
L.SOUND_READY_CHECK = "Ready check"
L.SOUND_LEVEL_UP = "Level up"
L.SOUND_PVP_FLAG = "PvP queue"
L.SOUND_AUCTION_CLOSE = "Auction house closes"
L.SOUND_MAP_PING = "Map ping"
L.SOUND_QUEST_COMPLETE = "Quest complete"
L.SOUND_TELL = "Whisper"
L.SOUND_ALARM = "Alarm clock"
L.SOUND_BELL = "Bell"

L.ALERT_lowHealth = "Low health"
L.MOVE_ON = "Drag the labels to move the alerts. Type /rb move again when done."
L.MOVE_OFF = "Alerts locked in place."
