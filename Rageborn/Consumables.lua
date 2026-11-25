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
        dps = {
            { "flask", {
                { 274274, "Flask of Natural Aggression", L.CONS_F_274274, prof = "alchemy", skill = 300, mats = { { 248822, 1, "Death Lotus" }, { 248821, 18, "Demonsage" }, { 13465, 6, "Mountain Silversage" }, { 18256, 1, "Imbued Vial" } }, from = L.CONS_FROM_hyjal },
                { 274275, "Flask of Natural Precision", L.CONS_F_274275, prof = "alchemy", skill = 300, mats = { { 248822, 1, "Death Lotus" }, { 248823, 12, "Marefoil" }, { 13463, 9, "Dreamfoil" }, { 18256, 1, "Imbued Vial" } }, from = L.CONS_FROM_hyjal },
                { 274273, "Flask of Natural Accuracy", L.CONS_F_274273, prof = "alchemy", skill = 300, mats = { { 248822, 1, "Death Lotus" }, { 248821, 12, "Demonsage" }, { 13464, 9, "Golden Sansam" }, { 18256, 1, "Imbued Vial" } }, from = L.CONS_FROM_hyjal },
                { 274276, "Flask of Natural Swiftness", L.CONS_F_274276, prof = "alchemy", skill = 300, mats = { { 248822, 1, "Death Lotus" }, { 248823, 18, "Marefoil" }, { 13467, 6, "Icecap" }, { 18256, 1, "Imbued Vial" } }, from = L.CONS_FROM_hyjal },
                { 13510, "Flask of the Titans", L.CONS_F_13510, prof = "alchemy", skill = 300, mats = { { 8846, 30, "Gromsblood" }, { 13423, 10, "Stonescale Oil" }, { 13468, 1, "Black Lotus" }, { 8925, 1, "Crystal Vial" } }, from = L.CONS_FROM_drakk },
            } },
            { "elixir", {
                { 250351, "Elixir of the Grizzly", L.CONS_F_250351, prof = "alchemy", skill = 300, mats = { { 8846, 3, "Gromsblood" }, { 8839, 1, "Blindweed" }, { 8925, 1, "Crystal Vial" } }, from = L.CONS_FROM_favor240H },
                { 13452, "Elixir of the Mongoose", L.CONS_F_13452, prof = "alchemy", skill = 280, mats = { { 13465, 2, "Mountain Silversage" }, { 13466, 2, "Plaguebloom" }, { 8925, 1, "Crystal Vial" } } },
                { 250350, "Elixir of Ferocity", L.CONS_F_250350, prof = "alchemy", skill = 275, mats = { { 8846, 3, "Gromsblood" }, { 8845, 1, "Ghost Mushroom" }, { 8925, 1, "Crystal Vial" } }, from = L.CONS_FROM_favor180H },
                { 9206, "Elixir of Greater Strength", L.CONS_F_9206, prof = "alchemy", skill = 245, mats = { { 8838, 1, "Sungrass" }, { 8846, 1, "Gromsblood" }, { 8925, 1, "Crystal Vial" } } },
                { 8410, "R.O.I.D.S.", L.CONS_F_8410, from = L.CONS_FROM_blasted_u },
                { 13453, "Elixir of Brute Force", L.CONS_F_13453, prof = "alchemy", skill = 275, mats = { { 8846, 2, "Gromsblood" }, { 13466, 2, "Plaguebloom" }, { 8925, 1, "Crystal Vial" } } },
                { 12820, "Winterfall Firewater", L.CONS_F_12820, from = L.CONS_FROM_furbolg },
                { 246948, "Distilled Firewater", L.CONS_F_246948, prof = "alchemy", skill = 250, mats = { { 3819, 4, "Wintersbite" }, { 8846, 2, "Gromsblood" }, { 3372, 1, "Leaded Vial" } } },
                { 9187, "Elixir of Greater Agility", L.CONS_F_9187, prof = "alchemy", skill = 240, mats = { { 8838, 1, "Sungrass" }, { 3821, 1, "Goldthorn" }, { 8925, 1, "Crystal Vial" } } },
                { 8412, "Ground Scorpok Assay", L.CONS_F_8412, from = L.CONS_FROM_blasted_u },
            } },
            { "food", {
                { 20452, "Smoked Desert Dumplings", L.CONS_F_20452, prof = "cooking", skill = 285, mats = { { 20424, 1, "Sandworm Meat" }, { 3713, 1, "Soothing Spices" } } },
                { 250070, "Bear Bruscitti", L.CONS_F_250070, prof = "cooking", skill = 275, mats = { { 3730, 3, "Big Bear Meat" }, { 3713, 3, "Soothing Spices" } }, from = L.CONS_FROM_unknown },
                { 250071, "Steaming Stag Steak", L.CONS_F_250071, prof = "cooking", skill = 275, mats = { { 5471, 3, "Stag Meat" }, { 3713, 4, "Soothing Spices" } }, from = L.CONS_FROM_unknown },
                { 13934, "Mightfish Steak", L.CONS_F_13934, prof = "cooking", skill = 275, mats = { { 13893, 1, "Large Raw Mightfish" }, { 2692, 1, "Hot Spices" }, { 3713, 1, "Soothing Spices" } }, from = L.CONS_FROM_vendor },
                { 13928, "Grilled Squid", L.CONS_F_13928, prof = "cooking", skill = 240, mats = { { 13755, 1, "Raw Winter Squid" }, { 3713, 1, "Soothing Spices" } } },
                { 250069, "Flank au Poivre", L.CONS_F_250069, prof = "cooking", skill = 275, mats = { { 12203, 3, "Red Wolf Meat" }, { 3713, 3, "Soothing Spices" } }, from = L.CONS_FROM_unknown },
                { 250072, "Swiftstrike Steak", L.CONS_F_250072, prof = "cooking", skill = 275, mats = { { 12202, 3, "Tiger Meat" }, { 3713, 2, "Soothing Spices" } }, from = L.CONS_FROM_unknown },
                { 18045, "Tender Wolf Steak", L.CONS_F_18045, prof = "cooking", skill = 225, mats = { { 12208, 1, "Tender Wolf Meat" }, { 3713, 1, "Soothing Spices" } } },
                { 13810, "Blessed Sunfruit", L.CONS_F_13810 },
            } },
            { "weapon", {
                { 18262, "Elemental Sharpening Stone", L.CONS_F_18262, prof = "blacksmithing", skill = 300, mats = { { 7067, 2, "Elemental Earth" }, { 12365, 3, "Dense Stone" } }, from = L.CONS_FROM_mc },
                { 12404, "Dense Sharpening Stone", L.CONS_F_12404, prof = "blacksmithing", mats = { { 12365, 1, "Dense Stone" } } },
                { 12643, "Dense Weightstone", L.CONS_F_12643, prof = "blacksmithing", mats = { { 12365, 1, "Dense Stone" } } },
                { 23122, "Consecrated Sharpening Stone", L.CONS_F_23122 },
            } },
            { "combat", {
                { 13442, "Mighty Rage Potion", L.CONS_F_13442, prof = "alchemy", skill = 255, mats = { { 8846, 3, "Gromsblood" }, { 8925, 1, "Crystal Vial" } } },
                { 250943, "Major Frenzy Potion", L.CONS_F_250943, prof = "alchemy", skill = 290, mats = { { 13466, 3, "Plaguebloom" }, { 8839, 2, "Blindweed" }, { 18256, 1, "Imbued Vial" } } },
                { 250942, "Superior Frenzy Potion", L.CONS_F_250942, prof = "alchemy", skill = 240, mats = { { 8839, 3, "Blindweed" }, { 4625, 2, "Firebloom" }, { 8925, 1, "Crystal Vial" } } },
                { 5634, "Free Action Potion", L.CONS_F_5634, prof = "alchemy", skill = 150, mats = { { 6370, 2, "Blackmouth Oil" }, { 3820, 1, "Stranglekelp" }, { 3372, 1, "Leaded Vial" } } },
                { 20008, "Living Action Potion", L.CONS_F_20008, prof = "alchemy", skill = 285, mats = { { 13467, 2, "Icecap" }, { 13465, 2, "Mountain Silversage" }, { 10286, 2, "Heart of the Wild" }, { 8925, 1, "Crystal Vial" } } },
                { 3387, "Limited Invulnerability Potion", L.CONS_F_3387, prof = "alchemy", skill = 250, mats = { { 8839, 2, "Blindweed" }, { 8845, 1, "Ghost Mushroom" }, { 8925, 1, "Crystal Vial" } } },
                { 13446, "Major Healing Potion", L.CONS_F_13446, prof = "firstaid", skill = 275, mats = { { 8925, 1, "Crystal Vial" }, { 3713, 3, "Soothing Spices" }, { 13464, 1, "Golden Sansam" } } },
                { 11951, "Whipper Root Tuber", L.CONS_F_11951 },
                { 10646, "Goblin Sapper Charge", L.CONS_F_10646, prof = "engineering", skill = 205, mats = { { 4338, 1, "Mageweave Cloth" }, { 10505, 3, "Solid Blasting Powder" }, { 10560, 1, "Unstable Trigger" } } },
                { 14530, "Heavy Runecloth Bandage", L.CONS_F_14530, prof = "firstaid", skill = 260, mats = { { 14047, 2, "Runecloth" } } },
            } },
            { "enchant", {
                { spell = 20034, prof = "enchanting", skill = 300, mats = { { 14344, 4, "Large Brilliant Shard" }, { 12811, 2, "Righteous Orb" } } },
                { spell = 1248668, prof = "enchanting", skill = 290, mats = { { 14344, 8, "Large Brilliant Shard" }, { 16203, 10, "Greater Eternal Essence" }, { 16204, 8, "Illusion Dust" }, { 12363, 4, "Arcane Crystal" } } },
                { spell = 23799, prof = "enchanting", skill = 290, mats = { { 14344, 6, "Large Brilliant Shard" }, { 16203, 6, "Greater Eternal Essence" }, { 16204, 4, "Illusion Dust" }, { 7076, 2, "Essence of Earth" } } },
                { spell = 20025, prof = "enchanting", skill = 300, mats = { { 14344, 4, "Large Brilliant Shard" }, { 16204, 15, "Illusion Dust" }, { 16203, 10, "Greater Eternal Essence" } } },
                { spell = 20010, prof = "enchanting", skill = 295, mats = { { 16204, 6, "Illusion Dust" }, { 16203, 6, "Greater Eternal Essence" } } },
                { spell = 20013, prof = "enchanting", skill = 295, mats = { { 16203, 4, "Greater Eternal Essence" }, { 16204, 4, "Illusion Dust" } } },
                { spell = 20023, prof = "enchanting", skill = 295, mats = { { 16203, 8, "Greater Eternal Essence" } } },
                { spell = 1328948, prof = "enchanting", skill = 280, mats = { { 11178, 2, "Large Radiant Shard" }, { 11176, 8, "Dream Dust" }, { 11175, 2, "Greater Nether Essence" }, { 12361, 1, "Blue Sapphire" } }, from = L.CONS_FROM_favor180H },
                { spell = 13882, prof = "enchanting", skill = 225, mats = { { 11174, 1, "Lesser Nether Essence" } } },
                { spell = 1249019, prof = "enchanting", skill = 210, mats = { { 11175, 4, "Greater Nether Essence" }, { 11178, 4, "Large Radiant Shard" }, { 11176, 10, "Dream Dust" }, { 249410, 4, "Sulfuric Acid" }, { 249425, 4, "Bauxite" } }, from = L.CONS_FROM_favor120F },
            } },
        },
        tank = {
            { "flask", {
                { 13510, "Flask of the Titans", L.CONS_F_13510, prof = "alchemy", skill = 300, mats = { { 8846, 30, "Gromsblood" }, { 13423, 10, "Stonescale Oil" }, { 13468, 1, "Black Lotus" }, { 8925, 1, "Crystal Vial" } }, from = L.CONS_FROM_drakk },
                { 274273, "Flask of Natural Accuracy", L.CONS_F_274273, prof = "alchemy", skill = 300, mats = { { 248822, 1, "Death Lotus" }, { 248821, 12, "Demonsage" }, { 13464, 9, "Golden Sansam" }, { 18256, 1, "Imbued Vial" } }, from = L.CONS_FROM_hyjal },
                { 274275, "Flask of Natural Precision", L.CONS_F_274275, prof = "alchemy", skill = 300, mats = { { 248822, 1, "Death Lotus" }, { 248823, 12, "Marefoil" }, { 13463, 9, "Dreamfoil" }, { 18256, 1, "Imbued Vial" } }, from = L.CONS_FROM_hyjal },
            } },
            { "elixir", {
                { 20079, "Spirit of Zanza", L.CONS_F_20079, from = L.CONS_FROM_zg },
                { 250329, "Elixir of the Phalanx", L.CONS_F_250329, prof = "alchemy", skill = 250, mats = { { 13464, 2, "Golden Sansam" }, { 8838, 4, "Sungrass" }, { 8925, 1, "Crystal Vial" } }, from = L.CONS_FROM_favor180H },
                { 250335, "Elixir of Greater Fortitude", L.CONS_F_250335, prof = "alchemy", skill = 200, mats = { { 8838, 4, "Sungrass" }, { 8925, 1, "Crystal Vial" } }, from = L.CONS_FROM_favor120F },
                { 13445, "Elixir of Greater Defense", L.CONS_F_13445, prof = "alchemy", skill = 265, mats = { { 13423, 2, "Stonescale Oil" }, { 8838, 1, "Sungrass" }, { 8925, 1, "Crystal Vial" } } },
                { 13453, "Elixir of Brute Force", L.CONS_F_13453, prof = "alchemy", skill = 275, mats = { { 8846, 2, "Gromsblood" }, { 13466, 2, "Plaguebloom" }, { 8925, 1, "Crystal Vial" } } },
                { 21151, "Rumsey Rum Black Label", L.CONS_F_21151, from = L.CONS_FROM_wreckage_u },
                { 18269, "Gordok Green Grog", L.CONS_F_18269, from = L.CONS_FROM_diremaul_u },
                { 250334, "Elixir of Fortitude", L.CONS_F_250334, prof = "alchemy", skill = 150, mats = { { 3821, 4, "Goldthorn" }, { 3372, 1, "Leaded Vial" } } },
                { 9088, "Gift of Arthas", L.CONS_F_9088, prof = "alchemy", skill = 240, mats = { { 8836, 1, "Arthas' Tears" }, { 8839, 1, "Blindweed" }, { 8925, 1, "Crystal Vial" } } },
                { 20004, "Major Troll's Blood Elixir", L.CONS_F_20004, prof = "alchemy", skill = 290, mats = { { 8846, 1, "Gromsblood" }, { 13466, 2, "Plaguebloom" }, { 8925, 1, "Crystal Vial" } } },
            } },
            { "food", {
                { 21023, "Dirge's Kickin' Chimaerok Chops", L.CONS_F_21023, prof = "cooking", skill = 300, mats = { { 2692, 1, "Hot Spices" }, { 9061, 1, "Goblin Rocket Fuel" }, { 8150, 1, "Deeprock Salt" }, { 21024, 1, "Chimaerok Tenderloin" } } },
                { 250068, "Savory Turtle Stew", L.CONS_F_250068, prof = "cooking", skill = 275, mats = { { 3712, 3, "Turtle Meat" }, { 3713, 3, "Soothing Spices" } }, from = L.CONS_FROM_unknown },
                { 20452, "Smoked Desert Dumplings", L.CONS_F_20452, prof = "cooking", skill = 285, mats = { { 20424, 1, "Sandworm Meat" }, { 3713, 1, "Soothing Spices" } } },
                { 250070, "Bear Bruscitti", L.CONS_F_250070, prof = "cooking", skill = 275, mats = { { 3730, 3, "Big Bear Meat" }, { 3713, 3, "Soothing Spices" } }, from = L.CONS_FROM_unknown },
            } },
            { "weapon", {
                { 18262, "Elemental Sharpening Stone", L.CONS_F_18262, prof = "blacksmithing", skill = 300, mats = { { 7067, 2, "Elemental Earth" }, { 12365, 3, "Dense Stone" } }, from = L.CONS_FROM_mc },
                { 12404, "Dense Sharpening Stone", L.CONS_F_12404, prof = "blacksmithing", mats = { { 12365, 1, "Dense Stone" } } },
                { 12643, "Dense Weightstone", L.CONS_F_12643, prof = "blacksmithing", mats = { { 12365, 1, "Dense Stone" } } },
            } },
            { "combat", {
                { 13455, "Greater Stoneshield Potion", L.CONS_F_13455, prof = "alchemy", skill = 280, mats = { { 13423, 3, "Stonescale Oil" }, { 10620, 1, "Thorium Ore" }, { 8925, 1, "Crystal Vial" } } },
                { 3387, "Limited Invulnerability Potion", L.CONS_F_3387, prof = "alchemy", skill = 250, mats = { { 8839, 2, "Blindweed" }, { 8845, 1, "Ghost Mushroom" }, { 8925, 1, "Crystal Vial" } } },
                { 13446, "Major Healing Potion", L.CONS_F_13446, prof = "firstaid", skill = 275, mats = { { 8925, 1, "Crystal Vial" }, { 3713, 3, "Soothing Spices" }, { 13464, 1, "Golden Sansam" } } },
                { 11951, "Whipper Root Tuber", L.CONS_F_11951 },
                { 5634, "Free Action Potion", L.CONS_F_5634, prof = "alchemy", skill = 150, mats = { { 6370, 2, "Blackmouth Oil" }, { 3820, 1, "Stranglekelp" }, { 3372, 1, "Leaded Vial" } } },
                { 20008, "Living Action Potion", L.CONS_F_20008, prof = "alchemy", skill = 285, mats = { { 13467, 2, "Icecap" }, { 13465, 2, "Mountain Silversage" }, { 10286, 2, "Heart of the Wild" }, { 8925, 1, "Crystal Vial" } } },
                { 13442, "Mighty Rage Potion", L.CONS_F_13442, prof = "alchemy", skill = 255, mats = { { 8846, 3, "Gromsblood" }, { 8925, 1, "Crystal Vial" } } },
                { 14530, "Heavy Runecloth Bandage", L.CONS_F_14530, prof = "firstaid", skill = 260, mats = { { 14047, 2, "Runecloth" } } },
            } },
            { "enchant", {
                { spell = 20034, prof = "enchanting", skill = 300, mats = { { 14344, 4, "Large Brilliant Shard" }, { 12811, 2, "Righteous Orb" } } },
                { spell = 1248760, prof = "enchanting", skill = 140, mats = { { 11083, 6, "Soul Dust" }, { 11084, 4, "Large Glimmering Shard" }, { 11082, 6, "Greater Astral Essence" }, { 249391, 4, "Pyrite" }, { 2775, 4, "Silver Ore" } }, from = L.CONS_FROM_favor45 },
                { spell = 23800, prof = "enchanting", skill = 290, mats = { { 14344, 6, "Large Brilliant Shard" }, { 16203, 6, "Greater Eternal Essence" }, { 16204, 4, "Illusion Dust" }, { 7082, 2, "Essence of Air" } } },
                { spell = 20026, prof = "enchanting", skill = 275, mats = { { 16204, 6, "Illusion Dust" }, { 14343, 1, "Small Brilliant Shard" } } },
                { spell = 20011, prof = "enchanting", skill = 300, mats = { { 16204, 15, "Illusion Dust" } } },
                { spell = 1248665, prof = "enchanting", skill = 300, mats = { { 14344, 3, "Large Brilliant Shard" } }, from = L.CONS_FROM_favor240H },
                { spell = 20020, prof = "enchanting", skill = 260, mats = { { 11176, 6, "Dream Dust" } } },
                { spell = 1328948, prof = "enchanting", skill = 280, mats = { { 11178, 2, "Large Radiant Shard" }, { 11176, 8, "Dream Dust" }, { 11175, 2, "Greater Nether Essence" }, { 12361, 1, "Blue Sapphire" } }, from = L.CONS_FROM_favor180H },
                { spell = 20015, prof = "enchanting", skill = 285, mats = { { 16204, 8, "Illusion Dust" } } },
                { spell = 20017, prof = "enchanting", skill = 265, mats = { { 11176, 6, "Dream Dust" } } },
                { spell = 1249060, prof = "enchanting", skill = 210, mats = { { 11175, 8, "Greater Nether Essence" }, { 11178, 2, "Large Radiant Shard" }, { 11176, 2, "Dream Dust" }, { 249409, 4, "Cerulean Dye" }, { 249430, 4, "Magenta Dye" } }, from = L.CONS_FROM_favor120F },
            } },
        },
    },
    era = {
        dps = {
            { "flask", {
                { 13510, "Flask of the Titans", L.CONS_E_13510, prof = "alchemy", skill = 300, mats = { { 8846, 30, "Gromsblood" }, { 13423, 10, "Stonescale Oil" }, { 13468, 1, "Black Lotus" }, { 8925, 1, "Crystal Vial" } }, extra = L.CONS_X_lab },
            } },
            { "elixir", {
                { 13452, "Elixir of the Mongoose", L.CONS_E_13452, prof = "alchemy", skill = 280, mats = { { 13465, 2, "Mountain Silversage" }, { 13466, 2, "Plaguebloom" }, { 8925, 1, "Crystal Vial" } } },
                { 12451, "Juju Power", L.CONS_E_12451, from = L.CONS_FROM_eko },
                { 9206, "Elixir of Giants", L.CONS_E_9206, prof = "alchemy", skill = 245, mats = { { 8838, 1, "Sungrass" }, { 8846, 1, "Gromsblood" }, { 8925, 1, "Crystal Vial" } } },
                { 12460, "Juju Might", L.CONS_E_12460, from = L.CONS_FROM_eko },
                { 12820, "Winterfall Firewater", L.CONS_E_12820, from = L.CONS_FROM_furbolg },
                { 8410, "R.O.I.D.S.", L.CONS_E_8410, from = L.CONS_FROM_blasted },
                { 8412, "Ground Scorpok Assay", L.CONS_E_8412, from = L.CONS_FROM_blasted },
                { 9187, "Elixir of Greater Agility", L.CONS_E_9187, prof = "alchemy", skill = 240, mats = { { 8838, 1, "Sungrass" }, { 3821, 1, "Goldthorn" }, { 8925, 1, "Crystal Vial" } } },
            } },
            { "food", {
                { 20452, "Smoked Desert Dumplings", L.CONS_E_20452, prof = "cooking", skill = 285, mats = { { 20424, 1, "Sandworm Meat" }, { 3713, 1, "Soothing Spices" } } },
                { 13810, "Blessed Sunfruit", L.CONS_E_13810, from = L.CONS_FROM_argent },
                { 13928, "Grilled Squid", L.CONS_E_13928, prof = "cooking", skill = 240, mats = { { 13755, 1, "Winter Squid" }, { 3713, 1, "Soothing Spices" } } },
                { 18045, "Tender Wolf Steak", L.CONS_E_18045, prof = "cooking", skill = 225, mats = { { 12208, 1, "Tender Wolf Meat" }, { 3713, 1, "Soothing Spices" } } },
            } },
            { "weapon", {
                { 18262, "Elemental Sharpening Stone", L.CONS_E_18262, prof = "blacksmithing", skill = 300, mats = { { 7067, 2, "Elemental Earth" }, { 12365, 3, "Dense Stone" } } },
                { 12404, "Dense Sharpening Stone", L.CONS_E_12404, prof = "blacksmithing", skill = 250, mats = { { 12365, 1, "Dense Stone" } } },
                { 12643, "Dense Weightstone", L.CONS_E_12643, prof = "blacksmithing", skill = 250, mats = { { 12365, 1, "Dense Stone" }, { 14047, 1, "Runecloth" } } },
                { 23122, "Consecrated Sharpening Stone", L.CONS_E_23122, from = L.CONS_FROM_argent },
            } },
            { "combat", {
                { 13442, "Mighty Rage Potion", L.CONS_E_13442, prof = "alchemy", skill = 255, mats = { { 8846, 3, "Gromsblood" }, { 8925, 1, "Crystal Vial" } } },
                { 5633, "Great Rage Potion", L.CONS_E_5633, prof = "alchemy", skill = 175, mats = { { 5637, 1, "Large Fang" }, { 3356, 1, "Kingsblood" }, { 3372, 1, "Leaded Vial" } } },
                { 5634, "Free Action Potion", L.CONS_E_5634, prof = "alchemy", skill = 150, mats = { { 6370, 2, "Blackmouth Oil" }, { 3820, 1, "Stranglekelp" }, { 3372, 1, "Leaded Vial" } } },
                { 3387, "Limited Invulnerability Potion", L.CONS_E_3387, prof = "alchemy", skill = 250, mats = { { 8839, 2, "Blindweed" }, { 8845, 1, "Ghost Mushroom" }, { 8925, 1, "Crystal Vial" } } },
                { 13446, "Major Healing Potion", L.CONS_E_13446, prof = "alchemy", skill = 275, mats = { { 13464, 2, "Golden Sansam" }, { 13465, 1, "Mountain Silversage" }, { 8925, 1, "Crystal Vial" } } },
                { 11951, "Whipper Root Tuber", L.CONS_E_11951, from = L.CONS_FROM_felwood },
                { 10646, "Goblin Sapper Charge", L.CONS_E_10646, prof = "engineering", skill = 205, mats = { { 4338, 1, "Mageweave Cloth" }, { 10505, 3, "Solid Blasting Powder" }, { 10560, 1, "Unstable Trigger" } } },
                { 9030, "Restorative Potion", L.CONS_E_9030, prof = "alchemy", skill = 210, mats = { { 7067, 1, "Elemental Earth" }, { 3821, 1, "Goldthorn" }, { 8925, 1, "Crystal Vial" } } },
                { 14530, "Heavy Runecloth Bandage", L.CONS_E_14530, prof = "firstaid", skill = 260, mats = { { 14047, 2, "Runecloth" } } },
            } },
            { "enchant", {
                { spell = 20034, prof = "enchanting", skill = 300, mats = { { 14344, 4, "Large Brilliant Shard" }, { 12811, 2, "Righteous Orb" } } },
                { spell = 23799, prof = "enchanting", skill = 290, mats = { { 14344, 6, "Large Brilliant Shard" }, { 16203, 6, "Greater Eternal Essence" }, { 16204, 4, "Illusion Dust" }, { 7076, 2, "Essence of Earth" } } },
                { spell = 20030, prof = "enchanting", skill = 295, mats = { { 14344, 4, "Large Brilliant Shard" }, { 16204, 10, "Illusion Dust" } } },
                { spell = 20025, prof = "enchanting", skill = 300, mats = { { 14344, 4, "Large Brilliant Shard" }, { 16204, 15, "Illusion Dust" }, { 16203, 10, "Greater Eternal Essence" } } },
                { spell = 20010, prof = "enchanting", skill = 295, mats = { { 16204, 6, "Illusion Dust" }, { 16203, 6, "Greater Eternal Essence" } } },
                { spell = 20013, prof = "enchanting", skill = 295, mats = { { 16203, 4, "Greater Eternal Essence" }, { 16204, 4, "Illusion Dust" } } },
                { spell = 25080, prof = "enchanting", skill = 300, mats = { { 20725, 3, "Nexus Crystal" }, { 14344, 8, "Large Brilliant Shard" }, { 7082, 4, "Essence of Air" } } },
                { spell = 13890, prof = "enchanting", skill = 225, mats = { { 11177, 1, "Small Radiant Shard" }, { 7909, 1, "Aquamarine" }, { 11174, 1, "Lesser Nether Essence" } } },
                { spell = 20023, prof = "enchanting", skill = 295, mats = { { 16203, 8, "Greater Eternal Essence" } } },
                { spell = 13882, prof = "enchanting", skill = 225, mats = { { 11174, 2, "Lesser Nether Essence" } } },
            } },
        },
        tank = {
            { "flask", {
                { 13510, "Flask of the Titans", L.CONS_E_13510, prof = "alchemy", skill = 300, mats = { { 8846, 30, "Gromsblood" }, { 13423, 10, "Stonescale Oil" }, { 13468, 1, "Black Lotus" }, { 8925, 1, "Crystal Vial" } }, extra = L.CONS_X_lab },
            } },
            { "elixir", {
                { 20079, "Spirit of Zanza", L.CONS_E_20079, from = L.CONS_FROM_zandalar },
                { 13445, "Elixir of Superior Defense", L.CONS_E_13445, prof = "alchemy", skill = 265, mats = { { 13423, 2, "Stonescale Oil" }, { 8838, 1, "Sungrass" }, { 8925, 1, "Crystal Vial" } } },
                { 3825, "Elixir of Fortitude", L.CONS_E_3825, prof = "alchemy", skill = 175, mats = { { 3355, 1, "Wild Steelbloom" }, { 3821, 1, "Goldthorn" }, { 3372, 1, "Leaded Vial" } } },
                { 21151, "Rumsey Rum Black Label", L.CONS_E_21151, from = L.CONS_FROM_wreckage },
                { 18269, "Gordok Green Grog", L.CONS_E_18269, from = L.CONS_FROM_diremaul },
                { 9088, "Gift of Arthas", L.CONS_E_9088, prof = "alchemy", skill = 240, mats = { { 8836, 1, "Arthas' Tears" }, { 8839, 1, "Blindweed" }, { 8925, 1, "Crystal Vial" } } },
                { 20004, "Major Troll's Blood Potion", L.CONS_E_20004, prof = "alchemy", skill = 290, mats = { { 8846, 1, "Gromsblood" }, { 13466, 2, "Plaguebloom" }, { 8925, 1, "Crystal Vial" } } },
                { 13452, "Elixir of the Mongoose", L.CONS_E_13452, prof = "alchemy", skill = 280, mats = { { 13465, 2, "Mountain Silversage" }, { 13466, 2, "Plaguebloom" }, { 8925, 1, "Crystal Vial" } } },
            } },
            { "food", {
                { 21023, "Dirge's Kickin' Chimaerok Chops", L.CONS_E_21023, prof = "cooking", skill = 300, mats = { { 2692, 1, "Hot Spices" }, { 9061, 1, "Goblin Rocket Fuel" }, { 8150, 1, "Deeprock Salt" }, { 21024, 1, "Chimaerok Tenderloin" } } },
                { 18045, "Tender Wolf Steak", L.CONS_E_18045, prof = "cooking", skill = 225, mats = { { 12208, 1, "Tender Wolf Meat" }, { 3713, 1, "Soothing Spices" } } },
                { 20452, "Smoked Desert Dumplings", L.CONS_E_20452, prof = "cooking", skill = 285, mats = { { 20424, 1, "Sandworm Meat" }, { 3713, 1, "Soothing Spices" } } },
            } },
            { "weapon", {
                { 18262, "Elemental Sharpening Stone", L.CONS_E_18262, prof = "blacksmithing", skill = 300, mats = { { 7067, 2, "Elemental Earth" }, { 12365, 3, "Dense Stone" } } },
                { 12404, "Dense Sharpening Stone", L.CONS_E_12404, prof = "blacksmithing", skill = 250, mats = { { 12365, 1, "Dense Stone" } } },
                { 12643, "Dense Weightstone", L.CONS_E_12643, prof = "blacksmithing", skill = 250, mats = { { 12365, 1, "Dense Stone" }, { 14047, 1, "Runecloth" } } },
            } },
            { "combat", {
                { 13455, "Greater Stoneshield Potion", L.CONS_E_13455, prof = "alchemy", skill = 280, mats = { { 13423, 3, "Stonescale Oil" }, { 10620, 1, "Thorium Ore" }, { 8925, 1, "Crystal Vial" } } },
                { 3387, "Limited Invulnerability Potion", L.CONS_E_3387, prof = "alchemy", skill = 250, mats = { { 8839, 2, "Blindweed" }, { 8845, 1, "Ghost Mushroom" }, { 8925, 1, "Crystal Vial" } } },
                { 13446, "Major Healing Potion", L.CONS_E_13446, prof = "alchemy", skill = 275, mats = { { 13464, 2, "Golden Sansam" }, { 13465, 1, "Mountain Silversage" }, { 8925, 1, "Crystal Vial" } } },
                { 11951, "Whipper Root Tuber", L.CONS_E_11951, from = L.CONS_FROM_felwood },
                { 5634, "Free Action Potion", L.CONS_E_5634, prof = "alchemy", skill = 150, mats = { { 6370, 2, "Blackmouth Oil" }, { 3820, 1, "Stranglekelp" }, { 3372, 1, "Leaded Vial" } } },
                { 13442, "Mighty Rage Potion", L.CONS_E_13442, prof = "alchemy", skill = 255, mats = { { 8846, 3, "Gromsblood" }, { 8925, 1, "Crystal Vial" } } },
                { 9030, "Restorative Potion", L.CONS_E_9030, prof = "alchemy", skill = 210, mats = { { 7067, 1, "Elemental Earth" }, { 3821, 1, "Goldthorn" }, { 8925, 1, "Crystal Vial" } } },
                { 14530, "Heavy Runecloth Bandage", L.CONS_E_14530, prof = "firstaid", skill = 260, mats = { { 14047, 2, "Runecloth" } } },
            } },
            { "enchant", {
                { spell = 20034, prof = "enchanting", skill = 300, mats = { { 14344, 4, "Large Brilliant Shard" }, { 12811, 2, "Righteous Orb" } } },
                { spell = 23800, prof = "enchanting", skill = 290, mats = { { 14344, 6, "Large Brilliant Shard" }, { 16203, 6, "Greater Eternal Essence" }, { 16204, 4, "Illusion Dust" }, { 7082, 2, "Essence of Air" } } },
                { spell = 20026, prof = "enchanting", skill = 275, mats = { { 16204, 6, "Illusion Dust" }, { 14343, 1, "Small Brilliant Shard" } } },
                { spell = 20025, prof = "enchanting", skill = 300, mats = { { 14344, 4, "Large Brilliant Shard" }, { 16204, 15, "Illusion Dust" }, { 16203, 10, "Greater Eternal Essence" } } },
                { spell = 20011, prof = "enchanting", skill = 300, mats = { { 16204, 15, "Illusion Dust" } } },
                { spell = 25072, prof = "enchanting", skill = 300, mats = { { 20725, 4, "Nexus Crystal" }, { 14344, 6, "Large Brilliant Shard" }, { 18512, 8, "Larval Acid" } } },
                { spell = 20020, prof = "enchanting", skill = 260, mats = { { 11176, 10, "Dream Dust" } } },
                { spell = 13890, prof = "enchanting", skill = 225, mats = { { 11177, 1, "Small Radiant Shard" }, { 7909, 1, "Aquamarine" }, { 11174, 1, "Lesser Nether Essence" } } },
                { spell = 20015, prof = "enchanting", skill = 285, mats = { { 16204, 8, "Illusion Dust" } } },
                { spell = 25086, prof = "enchanting", skill = 300, mats = { { 20725, 3, "Nexus Crystal" }, { 14344, 8, "Large Brilliant Shard" }, { 12809, 8, "Guardian Stone" } } },
                { spell = 20017, prof = "enchanting", skill = 265, mats = { { 11176, 10, "Dream Dust" } } },
            } },
        },
    },
}
Consumables.LISTS = LISTS

-- The sections for a role on this client: { { section key, rows }, ... }.
function Consumables.List(role)
    return LISTS[ns.ERA and "era" or "forever"][role] or {}
end
