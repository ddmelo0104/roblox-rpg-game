--!strict
--[[
	Config/Training.luau
	Training dummies of the prototype (US-009, US-012). The dev's starting values, to be tuned.
]]

return table.freeze({
	-- Dummy health. High on purpose, to test abilities for a long time.
	DUMMY_HEALTH = 1000,

	-- Seconds until a dummy comes back after being knocked down.
	DUMMY_RESPAWN_TIME = 5,

	-- Distance, in studs, in front of the SpawnLocation (or of the origin, if there is no spawn).
	DISTANCE_FROM_SPAWN = 20,

	-- Dummies side by side and studs between their centers (US-012): 3 dummies, to test whether the
	-- front slash hits 3 enemies at once.
	DUMMY_COUNT = 3,
	DUMMY_SPACING = 4,
})
