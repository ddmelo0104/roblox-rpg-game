--!strict
--[[
	Config/Debug.luau
	Developer tools of the prototype (US-014). They are not part of the game design.
]]

return table.freeze({
	-- Performance overlay for the terrain spike (FPS, memory, ping, streaming), in the top-left corner.
	PERF_OVERLAY_KEY = Enum.KeyCode.F3,

	-- Show the overlay from the start. Turn it on to measure on a phone, which has no keyboard.
	PERF_OVERLAY_VISIBLE = false,
})
