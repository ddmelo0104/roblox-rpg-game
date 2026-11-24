--!strict
--[[
	Config/Debug.luau
	Developer tools of the prototype (US-014, US-025, US-026). They are not part of the game design.
]]

return table.freeze({
	-- Performance overlay for the terrain spike (FPS, memory, ping, streaming), in the top-left corner.
	PERF_OVERLAY_KEY = Enum.KeyCode.F3,

	-- Show the overlay from the start. Turn it on to measure on a phone, which has no keyboard.
	PERF_OVERLAY_VISIBLE = false,

	-- Every enemy kill drops an item (US-026), to test the loot bags without waiting for the 5%.
	DROP_EVERY_KILL = false,

	-- Extra sleeping enemies far from the spawn (US-025), to measure the server cost of a zone full
	-- of enemies in the overlay. 0 turns it off.
	EXTRA_TEST_ENEMIES = 0,
})
