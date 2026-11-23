--!strict
--[[
	Config/Knockdown.luau
	Knockdown and full loot (EP-009, Zones and Risk tab). The seconds down and what each zone allows
	are in Config/Zones; these numbers are the same everywhere.
]]

return table.freeze({
	-- Seconds another player holds the prompt to finish (3) or to revive (5) a downed player. Damage
	-- taken while holding interrupts it.
	FINISH_TIME = 3,
	REVIVE_TIME = 5,
	-- How close (studs) a player must be to finish or revive.
	REACH = 8,

	-- A player who gets up (alone or revived) has this fraction of their health.
	GET_UP_HEALTH = 0.25,

	-- Durability (percentage points) every worn item loses when its owner gets up from a knockdown.
	DURABILITY_LOSS = 5,

	-- Full loot: the chance that each item is destroyed instead of going to the loot bag.
	ITEM_DESTROY_CHANCE = 0.25,
})
