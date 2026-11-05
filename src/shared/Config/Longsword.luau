--!strict
--[[
	Config/Longsword.luau
	The 3 abilities of the prototype's longsword (US-012), as Davi defined them on 2026-11-05:
	1. Front slash: 1.5 m forward, wide enough to hit 3 enemies side by side.
	2. Target strike: only on the locked enemy, with more damage.
	3. Spin: around oneself; its cooldown resets when it knocks down an enemy.
	Everything else (cost, cooldown, damage, strike range, spin radius and keys) is provisional, to
	be tuned by playing. Distances are written in meters and converted to studs here: in Roblox,
	1 stud = 0.28 m. `name` is the text the player sees, so it stays in Portuguese.

	Fields of each ability (the server checks all of them on start, with Shared.Abilities):
	- shape: "Front" (area in front, in the aim direction), "Target" (the locked target) or "Around"
	- range: length of the area (Front), max distance to the target (Target) or radius (Around)
	- width: side-to-side size of the area; only used by Front (0 for the others)
	- energyCost; cooldown, in seconds; damage: how much health it takes
	- resetOnKill: if the ability knocks down an enemy, its cooldown resets at once
]]

-- Studs in 1 meter.
local METER = 1 / 0.28

local LIST = {
	{
		id = "FrontSlash",
		name = "Corte frontal",
		key = Enum.KeyCode.Q,
		shape = "Front",
		range = 1.5 * METER, -- ≈ 5.4 studs
		width = 2.25 * METER, -- ≈ 8 studs: 3 enemies side by side, about 4 studs between their centers
		energyCost = 10,
		cooldown = 2,
		damage = 100,
		resetOnKill = false,
	},
	{
		id = "TargetStrike",
		name = "Golpe no alvo",
		key = Enum.KeyCode.E,
		shape = "Target",
		range = 1.5 * METER, -- provisional: the sword's reach
		width = 0,
		energyCost = 20,
		cooldown = 6,
		damage = 220,
		resetOnKill = false,
	},
	{
		id = "Spin",
		name = "Giro",
		key = Enum.KeyCode.R,
		shape = "Around",
		range = 1.5 * METER, -- provisional: the radius is the sword's reach
		width = 0,
		energyCost = 25,
		cooldown = 8,
		damage = 80,
		resetOnKill = true,
	},
}

for _, ability in LIST do
	table.freeze(ability)
end

return table.freeze(LIST)
