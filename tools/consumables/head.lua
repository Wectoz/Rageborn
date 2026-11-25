local ADDON, ns = ...

-- Rageborn: warrior consumables and enchants, best first, as data. Generated from the two
-- clients' own data tables; one list per client, because the items differ: Forever reworked
-- alchemy and cooking and renamed several items.
--   Forever  names, effects, professions, skill levels and materials read from the client's
--            data (build 1.60.1.71091); ranked by the effect numbers.
--   Era      the usual Classic order (also Hardcore); numbers, professions and materials
--            checked against the Era client's data (build 1.15.9.70576).
-- A row: { item, name (shown until the game has sent the item), note,
--          prof = profession, skill = level its recipe needs (nil = not in the data),
--          mats = { { item, count, name } }, extra / from = where else it comes from }
--   or   { spell = enchant, prof, skill, mats }: the game's tooltip says what it gives.
local L = ns.L

local Consumables = {}
ns.Consumables = Consumables

Consumables.ROLES = { "dps", "tank" }

local LISTS = {
    forever = {
@FOREVER@    },
    era = {
@ERA@    },
}
Consumables.LISTS = LISTS

-- The sections for a role on this client: { { section key, rows }, ... }.
function Consumables.List(role)
    return LISTS[ns.ERA and "era" or "forever"][role] or {}
end
