--!strict
--[[
	Config/Camera.luau
	Camera, combat mode (shift-lock) and target lock (Camera and Aim tab of the design doc). The tab
	says "to be defined in the prototype": these are the prototype's starting values (US-008, US-009).
]]

return table.freeze({
	-- Mouse-wheel zoom, in studs. The max keeps players from looking over walls in PvP.
	ZOOM_MIN = 6,
	ZOOM_MAX = 22,

	-- Camera over the right shoulder in combat mode (X to the right, Y up), in studs.
	SHOULDER_OFFSET = Vector3.new(1.75, 0.5, 0),

	-- Height, above the character's center, where aiming and the lock's line of sight start.
	FOCUS_HEIGHT = 1.5,

	-- Max distance, in studs, to lock onto a target and to keep the lock.
	LOCK_RANGE = 60,

	-- Degrees from the camera's center within which a target can be picked when locking.
	LOCK_ANGLE = 45,

	-- Seconds without line of sight before the lock releases by itself.
	LOST_SIGHT_RELEASE_TIME = 1.5,

	-- Provisional: whether the lock picks other players in PvP is an open question in the tab.
	LOCK_ON_PLAYERS = true,

	-- Provisional keys (open question in the tab). The middle mouse button also locks and releases.
	COMBAT_MODE_KEY = Enum.KeyCode.LeftControl,
	LOCK_KEY = Enum.KeyCode.T,
	SWITCH_TARGET_KEY = Enum.KeyCode.Tab,
})
