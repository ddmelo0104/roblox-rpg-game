--!strict
--[[
	Config/Zones.luau
	What each zone color changes in the code so far (Zones and Risk tab): the luck of the loot
	(US-026) and the fame multiplier (US-029). A spawn point says its zone in the Zone attribute.
	The rest of the tab (death, PvP, loot bags of a full loot) comes with EP-007 and EP-009.
]]

-- Zone name -> its rules. Typed with a string key, so a zone can be looked up by name.
local COLORS: { [string]: any } = {
	Blue = table.freeze({ luck = 1, fame = 1 }),
	Yellow = table.freeze({ luck = 1.25, fame = 1.1 }),
	Red = table.freeze({ luck = 1.75, fame = 1.3 }),
	Black = table.freeze({ luck = 2.5, fame = 1.5 }),
}

return table.freeze({
	COLORS = table.freeze(COLORS),

	-- The zone of a spawn point with no Zone attribute.
	DEFAULT_ZONE = "Blue",
})
