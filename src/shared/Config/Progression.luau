--!strict
--[[
	Config/Progression.luau
	Gear score numbers of the Progression tab (US-016). The names follow the tab's tuning table,
	translated (GS_POR_TIER becomes GS_PER_TIER, ESCALA_ATRIBUTO becomes ATTRIBUTE_SCALE…).
	Fame, specialization and mastery (EP-005) follow the tab's fame tables.
]]

return table.freeze({
	-- GS of an item = GS_PER_TIER × tier + GS_PER_ENHANCEMENT × enhancement + GS_RARITY[rarity]
	-- + GS_PER_SPEC_LEVEL × specialization + GS_PER_MASTERY_LEVEL × mastery of the line.
	GS_PER_TIER = 100,
	GS_PER_ENHANCEMENT = 100,
	GS_RARITY = table.freeze({ 0, 20, 40, 60, 100 }),
	GS_PER_SPEC_LEVEL = 2,
	GS_PER_MASTERY_LEVEL = 0.3,

	-- GS of the character = (WEAPON_GS_WEIGHT × weapon + head + chest + feet) / (WEAPON_GS_WEIGHT + 3).
	WEAPON_GS_WEIGHT = 2,

	-- Attribute multiplier = 1 + ATTRIBUTE_SCALE × (GS − 100) / 100. It scales damage and health.
	ATTRIBUTE_SCALE = 0.08,

	-- Fame of a kill (US-029): KILL_FAME_BASE × KILL_FAME_GROWTH^(zone tier − 1) for a common enemy,
	-- times ELITE_FAME_MULTIPLIER for an elite and times the zone's multiplier (Config/Zones).
	KILL_FAME_BASE = 10,
	KILL_FAME_GROWTH = 1.5,
	ELITE_FAME_MULTIPLIER = 3,
	-- Dungeon bosses (US-043): a mini-boss gives ×10 and a boss ×30 the fame of a common enemy.
	MINIBOSS_FAME_MULTIPLIER = 10,
	BOSS_FAME_MULTIPLIER = 30,

	-- In a group (US-046), each of the n members near a kill gets F × (1 + GROUP_FAME_BONUS × (n − 1))
	-- / n of the group's share of the fame: a group earns a bit more than its members alone.
	GROUP_FAME_BONUS = 0.15,

	-- Share of a fame gain that goes to the item worn in each slot. A line's mastery gets the sum of
	-- what its items got.
	FAME_SLOT_SHARES = table.freeze({ Weapon = 1, Chest = 0.5, Head = 0.25, Feet = 0.25 }),

	-- Levels of specialization and mastery (US-029): the total fame of a level is
	-- FAME_CURVE × level³, from 0 to MAX_LEVEL.
	FAME_CURVE = 2.5,
	MAX_LEVEL = 100,

	-- Line mastery needed to wear each tier, T1 … T8 (US-031).
	TIER_MASTERY = table.freeze({ 0, 5, 15, 30, 45, 60, 80, 100 }),
})
