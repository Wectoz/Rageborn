local ADDON, ns = ...

-- Rageborn: warrior consumables and enchants, best first, as data. One list per client,
-- because the items differ: Forever reworked alchemy and cooking and renamed several items.
--   Forever  effects and names read from the client's own item data (build 1.60.1.71091);
--            ranked by those numbers. Whether every item can be obtained yet, and which
--            elixirs stack with each other, the data doesn't say.
--   Era      the usual Classic order (also Hardcore); item numbers checked against the Era
--            client's data (build 1.15.9.70576).
-- A row is { item, name (shown until the game has sent the item), note } or { spell = enchant }.
-- Enchants carry no note: the game's own tooltip says what each does on this client.
local L = ns.L

local Consumables = {}
ns.Consumables = Consumables

Consumables.ROLES = { "dps", "tank" }

local LISTS = {
    forever = {
        dps = {
            { "flask", {
                { 274274, "Flask of Natural Aggression", L.CONS_F_274274 },
                { 274275, "Flask of Natural Precision", L.CONS_F_274275 },
                { 274273, "Flask of Natural Accuracy", L.CONS_F_274273 },
                { 274276, "Flask of Natural Swiftness", L.CONS_F_274276 },
                { 13510, "Flask of the Titans", L.CONS_F_13510 },
            } },
            { "elixir", {
                { 250351, "Elixir of the Grizzly", L.CONS_F_250351 },
                { 13452, "Elixir of the Mongoose", L.CONS_F_13452 },
                { 250350, "Elixir of Ferocity", L.CONS_F_250350 },
                { 9206, "Elixir of Greater Strength", L.CONS_F_9206 },
                { 8410, "R.O.I.D.S.", L.CONS_F_8410 },
                { 13453, "Elixir of Brute Force", L.CONS_F_13453 },
                { 12820, "Winterfall Firewater", L.CONS_F_12820 },
                { 246948, "Distilled Firewater", L.CONS_F_246948 },
                { 9187, "Elixir of Greater Agility", L.CONS_F_9187 },
                { 8412, "Ground Scorpok Assay", L.CONS_F_8412 },
            } },
            { "food", {
                { 20452, "Smoked Desert Dumplings", L.CONS_F_20452 },
                { 250070, "Bear Bruscitti", L.CONS_F_250070 },
                { 250071, "Steaming Stag Steak", L.CONS_F_250071 },
                { 13934, "Mightfish Steak", L.CONS_F_13934 },
                { 13928, "Grilled Squid", L.CONS_F_13928 },
                { 250069, "Flank au Poivre", L.CONS_F_250069 },
                { 250072, "Swiftstrike Steak", L.CONS_F_250072 },
                { 18045, "Tender Wolf Steak", L.CONS_F_18045 },
                { 13810, "Blessed Sunfruit", L.CONS_F_13810 },
            } },
            { "weapon", {
                { 18262, "Elemental Sharpening Stone", L.CONS_F_18262 },
                { 12404, "Dense Sharpening Stone", L.CONS_F_12404 },
                { 12643, "Dense Weightstone", L.CONS_F_12643 },
                { 23122, "Consecrated Sharpening Stone", L.CONS_F_23122 },
            } },
            { "combat", {
                { 13442, "Mighty Rage Potion", L.CONS_F_13442 },
                { 250943, "Major Frenzy Potion", L.CONS_F_250943 },
                { 250942, "Superior Frenzy Potion", L.CONS_F_250942 },
                { 5634, "Free Action Potion", L.CONS_F_5634 },
                { 20008, "Living Action Potion", L.CONS_F_20008 },
                { 3387, "Limited Invulnerability Potion", L.CONS_F_3387 },
                { 13446, "Major Healing Potion", L.CONS_F_13446 },
                { 11951, "Whipper Root Tuber", L.CONS_F_11951 },
                { 10646, "Goblin Sapper Charge", L.CONS_F_10646 },
                { 14530, "Heavy Runecloth Bandage", L.CONS_F_14530 },
            } },
            { "enchant", { { spell = 20034 }, { spell = 23799 }, { spell = 20030 }, { spell = 20025 }, { spell = 20010 }, { spell = 20013 }, { spell = 25080 }, { spell = 13890 }, { spell = 20023 }, { spell = 13882 } } },
        },
        tank = {
            { "flask", {
                { 13510, "Flask of the Titans", L.CONS_F_13510 },
                { 274273, "Flask of Natural Accuracy", L.CONS_F_274273 },
                { 274275, "Flask of Natural Precision", L.CONS_F_274275 },
            } },
            { "elixir", {
                { 20079, "Spirit of Zanza", L.CONS_F_20079 },
                { 250329, "Elixir of the Phalanx", L.CONS_F_250329 },
                { 250335, "Elixir of Greater Fortitude", L.CONS_F_250335 },
                { 13445, "Elixir of Greater Defense", L.CONS_F_13445 },
                { 13453, "Elixir of Brute Force", L.CONS_F_13453 },
                { 21151, "Rumsey Rum Black Label", L.CONS_F_21151 },
                { 18269, "Gordok Green Grog", L.CONS_F_18269 },
                { 250334, "Elixir of Fortitude", L.CONS_F_250334 },
                { 9088, "Gift of Arthas", L.CONS_F_9088 },
                { 20004, "Major Troll's Blood Elixir", L.CONS_F_20004 },
            } },
            { "food", {
                { 21023, "Dirge's Kickin' Chimaerok Chops", L.CONS_F_21023 },
                { 250068, "Savory Turtle Stew", L.CONS_F_250068 },
                { 20452, "Smoked Desert Dumplings", L.CONS_F_20452 },
                { 250070, "Bear Bruscitti", L.CONS_F_250070 },
            } },
            { "weapon", {
                { 18262, "Elemental Sharpening Stone", L.CONS_F_18262 },
                { 12404, "Dense Sharpening Stone", L.CONS_F_12404 },
                { 12643, "Dense Weightstone", L.CONS_F_12643 },
            } },
            { "combat", {
                { 13455, "Greater Stoneshield Potion", L.CONS_F_13455 },
                { 3387, "Limited Invulnerability Potion", L.CONS_F_3387 },
                { 13446, "Major Healing Potion", L.CONS_F_13446 },
                { 11951, "Whipper Root Tuber", L.CONS_F_11951 },
                { 5634, "Free Action Potion", L.CONS_F_5634 },
                { 20008, "Living Action Potion", L.CONS_F_20008 },
                { 13442, "Mighty Rage Potion", L.CONS_F_13442 },
                { 14530, "Heavy Runecloth Bandage", L.CONS_F_14530 },
            } },
            { "enchant", { { spell = 20034 }, { spell = 23800 }, { spell = 20026 }, { spell = 20025 }, { spell = 20011 }, { spell = 25072 }, { spell = 20020 }, { spell = 13890 }, { spell = 20015 }, { spell = 25086 }, { spell = 20017 } } },
        },
    },
    era = {
        dps = {
            { "flask", {
                { 13510, "Flask of the Titans", L.CONS_E_13510 },
            } },
            { "elixir", {
                { 13452, "Elixir of the Mongoose", L.CONS_E_13452 },
                { 12451, "Juju Power", L.CONS_E_12451 },
                { 9206, "Elixir of Giants", L.CONS_E_9206 },
                { 12460, "Juju Might", L.CONS_E_12460 },
                { 12820, "Winterfall Firewater", L.CONS_E_12820 },
                { 8410, "R.O.I.D.S.", L.CONS_E_8410 },
                { 8412, "Ground Scorpok Assay", L.CONS_E_8412 },
                { 9187, "Elixir of Greater Agility", L.CONS_E_9187 },
            } },
            { "food", {
                { 20452, "Smoked Desert Dumplings", L.CONS_E_20452 },
                { 13810, "Blessed Sunfruit", L.CONS_E_13810 },
                { 13928, "Grilled Squid", L.CONS_E_13928 },
                { 18045, "Tender Wolf Steak", L.CONS_E_18045 },
            } },
            { "weapon", {
                { 18262, "Elemental Sharpening Stone", L.CONS_E_18262 },
                { 12404, "Dense Sharpening Stone", L.CONS_E_12404 },
                { 12643, "Dense Weightstone", L.CONS_E_12643 },
                { 23122, "Consecrated Sharpening Stone", L.CONS_E_23122 },
            } },
            { "combat", {
                { 13442, "Mighty Rage Potion", L.CONS_E_13442 },
                { 5633, "Great Rage Potion", L.CONS_E_5633 },
                { 5634, "Free Action Potion", L.CONS_E_5634 },
                { 3387, "Limited Invulnerability Potion", L.CONS_E_3387 },
                { 13446, "Major Healing Potion", L.CONS_E_13446 },
                { 11951, "Whipper Root Tuber", L.CONS_E_11951 },
                { 10646, "Goblin Sapper Charge", L.CONS_E_10646 },
                { 9030, "Restorative Potion", L.CONS_E_9030 },
                { 14530, "Heavy Runecloth Bandage", L.CONS_E_14530 },
            } },
            { "enchant", { { spell = 20034 }, { spell = 23799 }, { spell = 20030 }, { spell = 20025 }, { spell = 20010 }, { spell = 20013 }, { spell = 25080 }, { spell = 13890 }, { spell = 20023 }, { spell = 13882 } } },
        },
        tank = {
            { "flask", {
                { 13510, "Flask of the Titans", L.CONS_E_13510 },
            } },
            { "elixir", {
                { 20079, "Spirit of Zanza", L.CONS_E_20079 },
                { 13445, "Elixir of Superior Defense", L.CONS_E_13445 },
                { 3825, "Elixir of Fortitude", L.CONS_E_3825 },
                { 21151, "Rumsey Rum Black Label", L.CONS_E_21151 },
                { 18269, "Gordok Green Grog", L.CONS_E_18269 },
                { 9088, "Gift of Arthas", L.CONS_E_9088 },
                { 20004, "Major Troll's Blood Potion", L.CONS_E_20004 },
                { 13452, "Elixir of the Mongoose", L.CONS_E_13452 },
            } },
            { "food", {
                { 21023, "Dirge's Kickin' Chimaerok Chops", L.CONS_E_21023 },
                { 18045, "Tender Wolf Steak", L.CONS_E_18045 },
                { 20452, "Smoked Desert Dumplings", L.CONS_E_20452 },
            } },
            { "weapon", {
                { 18262, "Elemental Sharpening Stone", L.CONS_E_18262 },
                { 12404, "Dense Sharpening Stone", L.CONS_E_12404 },
                { 12643, "Dense Weightstone", L.CONS_E_12643 },
            } },
            { "combat", {
                { 13455, "Greater Stoneshield Potion", L.CONS_E_13455 },
                { 3387, "Limited Invulnerability Potion", L.CONS_E_3387 },
                { 13446, "Major Healing Potion", L.CONS_E_13446 },
                { 11951, "Whipper Root Tuber", L.CONS_E_11951 },
                { 5634, "Free Action Potion", L.CONS_E_5634 },
                { 13442, "Mighty Rage Potion", L.CONS_E_13442 },
                { 9030, "Restorative Potion", L.CONS_E_9030 },
                { 14530, "Heavy Runecloth Bandage", L.CONS_E_14530 },
            } },
            { "enchant", { { spell = 20034 }, { spell = 23800 }, { spell = 20026 }, { spell = 20025 }, { spell = 20011 }, { spell = 25072 }, { spell = 20020 }, { spell = 13890 }, { spell = 20015 }, { spell = 25086 }, { spell = 20017 } } },
        },
    },
}
Consumables.LISTS = LISTS

-- The sections for a role on this client: { { section key, rows }, ... }.
function Consumables.List(role)
    return LISTS[ns.ERA and "era" or "forever"][role] or {}
end
