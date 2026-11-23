--!strict
--[[
	Loot.luau
	Pure loot rolls (US-020, Progression tab). The weight of each rarity r (1 = Common … 5 =
	Legendary) is base[r] × luck^(r − 1), normalized; the tier is the zone's tier, one below or one
	above (Config/Loot.TIER_OFFSETS), kept inside the tiers of the M1. Every roll takes a Random, so
	tests can repeat it with a seed. The server rolls; the client never does (ADR-002).
]]

local Config = script.Parent:WaitForChild("Config")
local ItemsConfig = require(Config:WaitForChild("Items") :: ModuleScript)
local LootConfig = require(Config:WaitForChild("Loot") :: ModuleScript)

local Loot = {}

-- The chance of each rarity, summing 1, for the base weights and the luck.
function Loot.rarityChances(baseWeights: { number }, luck: number): { number }
	local weights: { number } = {}
	local total = 0
	for rarity, base in baseWeights do
		local weight = base * luck ^ (rarity - 1)
		weights[rarity] = weight
		total += weight
	end
	for rarity, weight in weights do
		weights[rarity] = weight / total
	end
	return weights
end

-- Picks a rarity (1 … 5).
function Loot.rollRarity(baseWeights: { number }, luck: number, random: Random): number
	local chances = Loot.rarityChances(baseWeights, luck)
	local roll = random:NextNumber()
	for rarity, chance in chances do
		roll -= chance
		if roll < 0 then
			return rarity
		end
	end
	return 1
end

-- Picks the tier of a drop in a zone of tier `zoneTier`.
function Loot.rollTier(zoneTier: number, random: Random): number
	local roll = random:NextNumber()
	local offset = 0
	for _, option in LootConfig.TIER_OFFSETS do
		roll -= option.chance
		if roll < 0 then
			offset = option.offset
			break
		end
	end
	return math.clamp(zoneTier + offset, ItemsConfig.MIN_TIER, ItemsConfig.MAX_TIER)
end

-- Picks an item of the catalog, all with the same chance (sorted ids, so a seed repeats it).
function Loot.rollItemId(random: Random): string
	local ids: { string } = {}
	for itemId in ItemsConfig.ITEMS do
		table.insert(ids, itemId)
	end
	table.sort(ids)
	return ids[random:NextInteger(1, #ids)]
end

-- A full roll: item, tier and rarity.
function Loot.roll(zoneTier: number, luck: number, baseWeights: { number }, random: Random): (string, number, number)
	return Loot.rollItemId(random), Loot.rollTier(zoneTier, random), Loot.rollRarity(baseWeights, luck, random)
end

return table.freeze(Loot)
