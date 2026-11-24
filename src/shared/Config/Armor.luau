--!strict
--[[
	Config/Armor.luau
	What the chest and the boots add to the kit (US-024, Combat tab: "the chest ability" and "the dodge
	is defined by the boots"). Decided by the dev under Davi's delegation (2026-11-23,
	DECISOES-DELEGADAS), following the armor types Davi defined on 2026-11-04: light favors damage and
	cooldowns, medium is balanced, heavy is the tank. Names are what the player reads (Portuguese).
]]

return table.freeze({
	-- The chest ability's key (provisional; D is taken by WASD).
	CHEST_ABILITY_KEY = Enum.KeyCode.C,

	-- One ability per chest type. effect: "RestoreEnergy" (amount of energy), "Heal" (fraction of max
	-- health) or "Resistance" (extra resistance for `duration` seconds).
	CHEST_ABILITIES = table.freeze({
		Light = table.freeze({
			id = "Focus",
			name = "Foco",
			effect = "RestoreEnergy",
			amount = 30,
			duration = 0,
			energyCost = 0,
			cooldown = 20,
		}),
		Medium = table.freeze({
			id = "SecondWind",
			name = "Fôlego",
			effect = "Heal",
			amount = 0.2,
			duration = 0,
			energyCost = 15,
			cooldown = 18,
		}),
		Heavy = table.freeze({
			id = "Fortress",
			name = "Fortaleza",
			effect = "Resistance",
			amount = 0.4,
			duration = 4,
			energyCost = 15,
			cooldown = 22,
		}),
	}),

	-- The dodge of each boots type: dash distance (studs), invulnerability and cooldown (seconds).
	-- Without boots, the medium dodge.
	BOOTS_DODGES = table.freeze({
		Light = table.freeze({ distance = 14, invulnerableTime = 0.35, cooldown = 1.6 }),
		Medium = table.freeze({ distance = 12, invulnerableTime = 0.35, cooldown = 2 }),
		Heavy = table.freeze({ distance = 8, invulnerableTime = 0.45, cooldown = 2.5 }),
	}),
	DEFAULT_BOOTS = "Medium",
})
