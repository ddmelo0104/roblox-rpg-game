--!strict
--[[
	Config/Combat.luau
	Energy and ability hits (Combat and Abilities tab of the design doc). The tab says "to be defined
	in the prototype": these are US-012's starting values, to be tuned by playing. The cost, cooldown,
	damage and range of each ability live in the weapon data (Config/Longsword).
]]

return table.freeze({
	-- Max energy and how much comes back per second, in or out of combat (ENERGIA_MAX and
	-- ENERGIA_REGEN in the design doc). Provisional.
	MAX_ENERGY = 100,
	ENERGY_REGEN = 5,

	-- ADR-009 (proposed): extra studs the server accepts in range and area because of network lag
	-- (MARGEM_LAG in the design doc). The client checks without this margin before requesting.
	LAG_MARGIN = 1.5,

	-- Max height difference, in studs, between the attacker's center and the target's center.
	MAX_HIT_HEIGHT = 5,
})
