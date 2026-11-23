--!strict
--[[
	Items.luau
	Item types and pure math (US-016, Progression tab, ADR-006): the GS of an item, the GS of a
	character and the attributes that come from what the character wears. The catalog lives in
	Config/Items and the numbers in Config/Progression. Only the server creates item records
	(InventoryService); the client receives copies.
]]

local Config = script.Parent:WaitForChild("Config")
local ArmorConfig = require(Config:WaitForChild("Armor") :: ModuleScript)
local ItemsConfig = require(Config:WaitForChild("Items") :: ModuleScript)
local ProgressionConfig = require(Config:WaitForChild("Progression") :: ModuleScript)

-- A copy of an item: what the server keeps and what the client receives to show.
export type ItemRecord = {
	uid: string,
	itemId: string,
	tier: number,
	-- 1 = Common … 5 = Legendary
	rarity: number,
	-- 0 to 100; a broken item (0) counts no GS and gives no bonus until repaired
	durability: number,
}

-- What the character wears: slot name -> item.
export type Equipped = { [string]: ItemRecord }

export type Stats = {
	gearScore: number,
	damageMultiplier: number,
	healthMultiplier: number,
	-- Fraction of the damage taken that is removed.
	resistance: number,
	cooldownMultiplier: number,
}

local Items = {}

-- Player attribute with the character's GS, for the HUD (set by StatsService).
Items.GEAR_SCORE_ATTRIBUTE = "GearScore"

-- The catalog entry of an item (name, slot, line and, on armor, armorType), or nil.
function Items.definition(itemId: string): any
	return ItemsConfig.ITEMS[itemId]
end

-- The specialization level of a worn item and the mastery level of its line (EP-005), given by
-- Shared.Mastery from a player's fame.
export type LevelsOf = (record: ItemRecord) -> (number, number)

-- GS of one item, with its specialization level and its line's mastery level (0 if not given).
function Items.itemGearScore(record: ItemRecord, specialization: number?, mastery: number?): number
	if record.durability <= 0 then
		return 0
	end
	return ProgressionConfig.GS_PER_TIER * record.tier
		+ (ProgressionConfig.GS_RARITY[record.rarity] or 0)
		+ ProgressionConfig.GS_PER_SPEC_LEVEL * (specialization or 0)
		+ ProgressionConfig.GS_PER_MASTERY_LEVEL * (mastery or 0)
end

-- GS of the character: the average of the slots, with the weapon counting WEAPON_GS_WEIGHT times.
-- An empty slot counts 0. `levelsOf` adds the specialization and mastery of each item.
function Items.characterGearScore(equipped: Equipped, levelsOf: LevelsOf?): number
	local weight = ProgressionConfig.WEAPON_GS_WEIGHT
	local total = 0
	for _, slot in ItemsConfig.SLOTS do
		local record = equipped[slot]
		if record then
			local specialization, mastery = 0, 0
			if levelsOf then
				specialization, mastery = levelsOf(record)
			end
			total += Items.itemGearScore(record, specialization, mastery) * (if slot == "Weapon" then weight else 1)
		end
	end
	return total / (weight + #ItemsConfig.SLOTS - 1)
end

-- Multiplier of damage and health for a GS.
function Items.attributeMultiplier(gearScore: number): number
	return 1 + ProgressionConfig.ATTRIBUTE_SCALE * (gearScore - 100) / 100
end

-- Everything the equipment gives the character: GS, damage and health multipliers, resistance and
-- cooldown multiplier, adding the bonuses of each armor piece by its type. `levelsOf` adds the
-- specialization and mastery to the GS.
function Items.characterStats(equipped: Equipped, levelsOf: LevelsOf?): Stats
	local gearScore = Items.characterGearScore(equipped, levelsOf)
	local multiplier = Items.attributeMultiplier(gearScore)
	local damage, health, resistance, cooldownReduction = 0, 0, 0, 0
	for _, record in equipped do
		local definition = Items.definition(record.itemId)
		local bonuses = if definition
				and definition.armorType
				and record.durability > 0
			then ItemsConfig.ARMOR_BONUSES[definition.armorType]
			else nil
		if bonuses then
			damage += bonuses.damage
			health += bonuses.health
			resistance += bonuses.resistance
			cooldownReduction += bonuses.cooldownReduction
		end
	end
	return {
		gearScore = gearScore,
		damageMultiplier = multiplier * (1 + damage),
		healthMultiplier = multiplier * (1 + health),
		resistance = math.min(resistance, ItemsConfig.MAX_RESISTANCE),
		cooldownMultiplier = math.max(1 - cooldownReduction, ItemsConfig.MIN_COOLDOWN_MULTIPLIER),
	}
end

-- The armor type of what is worn in `slot`, or nil.
local function armorTypeIn(equipped: Equipped, slot: string): string?
	local record = equipped[slot]
	local definition = if record then Items.definition(record.itemId) else nil
	return if definition then definition.armorType else nil
end

-- The chest ability of what the character wears (US-024), or nil without a chest.
function Items.chestAbilityOf(equipped: Equipped): any
	local armorType = armorTypeIn(equipped, "Chest")
	return if armorType then ArmorConfig.CHEST_ABILITIES[armorType] else nil
end

-- The dodge given by the boots (US-024); without boots, the default one.
function Items.dodgeOf(equipped: Equipped): any
	local armorType = armorTypeIn(equipped, "Feet") or ArmorConfig.DEFAULT_BOOTS
	return ArmorConfig.BOOTS_DODGES[armorType]
end

-- What the player reads for an item, e.g. "Espada longa T3 (Raro)".
function Items.displayName(record: ItemRecord): string
	local definition = Items.definition(record.itemId)
	local name = if definition then definition.name else record.itemId
	return `{name} T{record.tier} ({ItemsConfig.RARITY_NAMES[record.rarity] or "?"})`
end

return table.freeze(Items)
