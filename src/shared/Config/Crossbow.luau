--!strict
--[[
	Config/Crossbow.luau
	The crossbow's kit (US-022): slower, heavier ranged burst. Abilities decided by the dev under
	Davi's delegation (2026-11-23, DECISOES-DELEGADAS). Fields explained in Config/Longsword.
]]

local LIST = {
	{
		id = "HeavyBolt",
		name = "Virote pesado",
		key = Enum.KeyCode.Q,
		shape = "Target",
		range = 40,
		width = 0,
		radius = 0,
		energyCost = 15,
		cooldown = 5,
		damage = 180,
		resetOnKill = false,
	},
	{
		id = "Volley",
		name = "Rajada",
		key = Enum.KeyCode.E,
		shape = "Front",
		range = 30,
		width = 6,
		radius = 0,
		energyCost = 20,
		cooldown = 7,
		damage = 120,
		resetOnKill = false,
	},
	{
		id = "ExplosiveBolt",
		name = "Tiro explosivo",
		key = Enum.KeyCode.R,
		shape = "Ground",
		range = 35,
		width = 0,
		radius = 6,
		energyCost = 32,
		cooldown = 12,
		damage = 200,
		resetOnKill = false,
	},
}

for _, ability in LIST do
	table.freeze(ability)
end

return table.freeze({
	BASIC_ATTACK = table.freeze({ range = 35, damage = 45, interval = 1.4, coneAngle = 30 }),
	ABILITIES = table.freeze(LIST),
})
