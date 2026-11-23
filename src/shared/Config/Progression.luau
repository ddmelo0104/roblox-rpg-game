--!strict
--[[
	Config/Progression.luau
	Gear score numbers of the Progression tab (US-016). The names follow the tab's tuning table,
	translated (GS_POR_TIER becomes GS_PER_TIER, ESCALA_ATRIBUTO becomes ATTRIBUTE_SCALE…).
	Fame and mastery come with EP-005.
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
})
