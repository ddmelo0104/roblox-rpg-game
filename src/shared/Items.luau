--!strict
--[[
	Items.luau
	Item types and pure math (US-016, Progression tab, ADR-006): the GS of an item, the GS of a
	character and the attributes that come from what the character wears. The catalog lives in
	Config/Items and the numbers in Config/Progression. Only the server creates item records
	(InventoryService); the client receives copies.
]]

local Config = script.Parent:WaitForChild("Config")
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

-- GS of one item. Specialization and mastery come with EP-005; until then they are 0.
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
-- An empty slot counts 0.
function Items.characterGearScore(equipped: Equipped): number
	local weight = ProgressionConfig.WEAPON_GS_WEIGHT
	local total = 0
	for _, slot in ItemsConfig.SLOTS do
		local record = equipped[slot]
		if record then
			total += Items.itemGearScore(record) * (if slot == "Weapon" then weight else 1)
		end
	end
	return total / (weight + #ItemsConfig.SLOTS - 1)
end

-- Multiplier of damage and health for a GS.
function Items.attributeMultiplier(gearScore: number): number
	return 1 + ProgressionConfig.ATTRIBUTE_SCALE * (gearScore - 100) / 100
end

-- Everything the equipment gives the character: GS, damage and health multipliers, resistance and
-- cooldown multiplier, adding the bonuses of each armor piece by its type.
function Items.characterStats(equipped: Equipped): Stats
	local gearScore = Items.characterGearScore(equipped)
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

-- What the player reads for an item, e.g. "Espada longa T3 (Raro)".
function Items.displayName(record: ItemRecord): string
	local definition = Items.definition(record.itemId)
	local name = if definition then definition.name else record.itemId
	return `{name} T{record.tier} ({ItemsConfig.RARITY_NAMES[record.rarity] or "?"})`
end

return table.freeze(Items)
