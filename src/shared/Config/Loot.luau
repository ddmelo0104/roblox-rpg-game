--!strict
--[[
	Config/Loot.luau
	Loot rolls of the Progression tab (US-020): rarity weights, how the zone's luck shifts them, and
	the tier of what drops. Used by the chests now and by the enemies and dungeons later.
]]

return table.freeze({
	-- Base weight of each rarity (Common … Legendary), with luck 1.
	ENEMY_RARITY_WEIGHTS = table.freeze({ 70, 22, 6, 1.8, 0.2 }),
	BOSS_CHEST_RARITY_WEIGHTS = table.freeze({ 40, 35, 17, 6.5, 1.5 }),

	-- Tier of the item relative to the zone's tier, and the chance of each (75% / 20% / 5%).
	TIER_OFFSETS = table.freeze({
		table.freeze({ offset = 0, chance = 0.75 }),
		table.freeze({ offset = -1, chance = 0.2 }),
		table.freeze({ offset = 1, chance = 0.05 }),
	}),

	-- Chance of an item per kill (EP-008): a common enemy 5%, an elite 25%.
	ITEM_CHANCE_COMMON = 0.05,
	ITEM_CHANCE_ELITE = 0.25,

	-- A player must be this close (studs) to open a chest; the server checks it.
	CHEST_REACH = 12,

	-- Test chest (US-020): zone tier and luck of its rolls, and seconds a player waits between openings.
	TEST_CHEST_TIER = 1,
	TEST_CHEST_LUCK = 1,
	TEST_CHEST_COOLDOWN = 1,
})
