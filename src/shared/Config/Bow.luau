--!strict
--[[
	Config/Bow.luau
	The bow's kit (US-022): mobile ranged damage. Abilities decided by the dev under Davi's delegation
	(2026-11-23, DECISOES-DELEGADAS); ranged abilities cost more energy than melee ones, as the Combat
	tab asks. Fields explained in Config/Longsword. Distances in studs.
]]

local LIST = {
	{
		id = "PiercingArrow",
		name = "Flecha perfurante",
		key = Enum.KeyCode.Q,
		shape = "Front", -- a long, narrow line that goes through every enemy in it
		range = 40,
		width = 3,
		radius = 0,
		energyCost = 12,
		cooldown = 4,
		damage = 90,
		resetOnKill = false,
	},
	{
		id = "AimedShot",
		name = "Tiro certeiro",
		key = Enum.KeyCode.E,
		shape = "Target",
		range = 45,
		width = 0,
		radius = 0,
		energyCost = 18,
		cooldown = 6,
		damage = 160,
		resetOnKill = false,
	},
	{
		id = "ArrowRain",
		name = "Chuva de flechas",
		key = Enum.KeyCode.R,
		shape = "Ground",
		range = 40,
		width = 0,
		radius = 8,
		energyCost = 28,
		cooldown = 10,
		damage = 110,
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
	BASIC_ATTACK = table.freeze({ range = 40, damage = 30, interval = 1, coneAngle = 30 }),
	ABILITIES = table.freeze(LIST),
})
