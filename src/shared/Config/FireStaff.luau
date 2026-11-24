--!strict
--[[
	Config/FireStaff.luau
	The fire staff's kit (US-022): the mage, with the highest damage and the highest energy costs (the
	Combat tab wants energy to hold mages back). Abilities decided by the dev under Davi's delegation
	(2026-11-23, DECISOES-DELEGADAS). Fields explained in Config/Longsword.
]]

local LIST = {
	{
		id = "Fireball",
		name = "Bola de fogo",
		key = Enum.KeyCode.Q,
		shape = "Target",
		range = 45,
		width = 0,
		radius = 0,
		energyCost = 18,
		cooldown = 3,
		damage = 140,
		resetOnKill = false,
	},
	{
		id = "FlameWave",
		name = "Onda de chamas",
		key = Enum.KeyCode.E,
		shape = "Front",
		range = 25,
		width = 8,
		radius = 0,
		energyCost = 25,
		cooldown = 8,
		damage = 130,
		resetOnKill = false,
	},
	{
		id = "FirePillar",
		name = "Coluna de fogo",
		key = Enum.KeyCode.R,
		shape = "Ground",
		range = 40,
		width = 0,
		radius = 9,
		energyCost = 40,
		cooldown = 14,
		damage = 220,
		resetOnKill = false,
	},
}

for _, ability in LIST do
	table.freeze(ability)
end

return table.freeze({
	-- How the defense sees this weapon's hits on a player (US-036): "Melee" (dodge or parry) or
	-- "Ranged" (only the dodge).
	HIT_KIND = "Ranged",
	BASIC_ATTACK = table.freeze({ range = 35, damage = 35, interval = 1.1, coneAngle = 30 }),
	ABILITIES = table.freeze(LIST),
})
