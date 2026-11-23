--!strict
--[[
	Config/Items.luau
	The items of the M1 (US-016, Progression and Weapons and Armor tabs). Items are standardized, as
	in Albion: a T4 Rare Longsword is always the same, and only tier, rarity and durability change
	between copies (ADR-006). `name` is what the player reads, so it stays in Portuguese.

	Weapons: longsword, bow, crossbow and fire staff (Davi, 2026-11-04). Armor: light, medium and
	heavy, for the head, chest and feet, mixable piece by piece (Davi, 2026-11-04). In the
	Progression tab the armor lines are Cloth (light), Leather (medium) and Plate (heavy).
]]

return table.freeze({
	-- Equipment slots of the M1, and the names the player reads.
	SLOTS = table.freeze({ "Weapon", "Head", "Chest", "Feet" }),
	SLOT_NAMES = table.freeze({ Weapon = "Arma", Head = "Elmo", Chest = "Peitoral", Feet = "Botas" }),

	-- Tiers of the M1 (the full game goes up to T8).
	MIN_TIER = 1,
	MAX_TIER = 4,

	-- Rarities from 1 (Common) to 5 (Legendary), as the player reads them.
	RARITY_NAMES = table.freeze({ "Comum", "Incomum", "Raro", "Épico", "Lendário" }),

	-- The catalog. `line` is where fame and mastery go (EP-005); `armorType` only exists on armor.
	ITEMS = table.freeze({
		Longsword = table.freeze({ name = "Espada longa", slot = "Weapon", line = "Swords" }),
		Bow = table.freeze({ name = "Arco", slot = "Weapon", line = "Bows" }),
		Crossbow = table.freeze({ name = "Besta", slot = "Weapon", line = "Crossbows" }),
		FireStaff = table.freeze({ name = "Cajado de fogo", slot = "Weapon", line = "FireStaffs" }),

		ClothHood = table.freeze({ name = "Capuz de tecido", slot = "Head", line = "Cloth", armorType = "Light" }),
		ClothRobe = table.freeze({ name = "Túnica de tecido", slot = "Chest", line = "Cloth", armorType = "Light" }),
		ClothShoes = table.freeze({ name = "Sapatos de tecido", slot = "Feet", line = "Cloth", armorType = "Light" }),

		LeatherHood = table.freeze({ name = "Capuz de couro", slot = "Head", line = "Leather", armorType = "Medium" }),
		LeatherJacket = table.freeze({
			name = "Jaqueta de couro",
			slot = "Chest",
			line = "Leather",
			armorType = "Medium",
		}),
		LeatherBoots = table.freeze({ name = "Botas de couro", slot = "Feet", line = "Leather", armorType = "Medium" }),

		PlateHelmet = table.freeze({ name = "Elmo de placa", slot = "Head", line = "Plate", armorType = "Heavy" }),
		PlateArmor = table.freeze({ name = "Armadura de placa", slot = "Chest", line = "Plate", armorType = "Heavy" }),
		PlateBoots = table.freeze({ name = "Botas de placa", slot = "Feet", line = "Plate", armorType = "Heavy" }),
	}),

	-- Bonuses of each armor piece by type, as fractions: light gives damage and cooldown, medium gives
	-- damage and some health, heavy gives health, resistance and cooldown (Davi, 2026-11-04). The
	-- numbers are the dev's choice (2026-11-23, DECISOES-DELEGADAS), to tune by playing.
	ARMOR_BONUSES = table.freeze({
		Light = table.freeze({ damage = 0.04, health = 0, resistance = 0, cooldownReduction = 0.04 }),
		Medium = table.freeze({ damage = 0.03, health = 0.05, resistance = 0, cooldownReduction = 0 }),
		Heavy = table.freeze({ damage = 0, health = 0.1, resistance = 0.06, cooldownReduction = 0.02 }),
	}),

	-- Limits, so stacking bonuses never makes a character immune or cooldown-free.
	MAX_RESISTANCE = 0.75,
	MIN_COOLDOWN_MULTIPLIER = 0.25,

	-- Bag slots (dev's choice, 2026-11-23).
	INVENTORY_SIZE = 24,

	-- What every new character gets, equipped, at T1 Common: the restart kit of the Zones and Risk tab.
	STARTER_KIT = table.freeze({ "Longsword", "LeatherHood", "LeatherJacket", "LeatherBoots" }),
})
