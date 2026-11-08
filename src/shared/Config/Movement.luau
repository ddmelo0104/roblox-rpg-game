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
})
