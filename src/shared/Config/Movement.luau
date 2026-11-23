--!strict
--[[
	Config/Movement.luau
	Movement numbers and keys (Movement tab of the design doc). The tab says "to be defined in the
	prototype": these are the prototype's starting values (US-008, US-010), to be tuned by playing.
]]

return table.freeze({
	-- studs/s. Roblox default, as the Movement tab mentions (VELOCIDADE_ANDAR in the design doc).
	WALK_SPEED = 16,

	-- studs/s. Prototype value.
	SPRINT_SPEED = 24,

	-- studs. Roblox default; prototype value.
	JUMP_HEIGHT = 7.2,

	-- Hold to sprint. Provisional: the PC keys are an open question in the tab.
	SPRINT_KEY = Enum.KeyCode.LeftShift,

	-- US-015: in combat, a jump can only follow the previous one after this many seconds (Davi asked for
	-- a limited jump in combat on 2026-11-23; the interval is the dev's choice). Out of combat, jumping
	-- is free.
	JUMP_COOLDOWN_IN_COMBAT = 1.5,

	-- US-011, ADR-010 (proposed): the server checks how far each character moves.
	-- Seconds between checks.
	VALIDATION_INTERVAL = 0.5,

	-- How much faster than the allowed speed is still accepted: 0.25 means 25% (MARGEM_VELOCIDADE in
	-- the design doc).
	SPEED_MARGIN = 0.25,

	-- Studs always accepted on top of that in each check (small physics pushes, slopes).
	DISTANCE_TOLERANCE = 4,

	-- Seconds of movement a player can save up while standing still or lagging and then deliver at
	-- once, without being pulled back.
	MAX_LAG_BURST = 1.5,
})
