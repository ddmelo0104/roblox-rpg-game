--!strict
--[[
	Enemies.luau
	Pure rules of the enemies (EP-008), for the server and the client:
	- the kind of each enemy (Config/Enemies);
	- the tier scaling (US-027): an enemy of a zone of tier T is as strong as a player with the
	  zone's recommended GS, 100 × T + 50 (Zones and Risk tab), through the attribute multiplier of
	  the Progression tab;
	- elites, and the item chance per kill (Config/Loot);
	- who earns a kill (US-026): every player who dealt at least a share of the damage;
	- where the server publishes the numbers of the performance overlay (US-025).
]]

local EnemiesConfig = require(script.Parent.Config.Enemies)
local Items = require(script.Parent.Items)
local LootConfig = require(script.Parent.Config.Loot)
local ProgressionConfig = require(script.Parent.Config.Progression)
local Zones = require(script.Parent.Zones)

export type DeathBlast = {
	radius: number,
	damage: number,
	delay: number,
}

export type Kind = {
	name: string,
	faction: string,
	attack: "Melee" | "Ranged",
	health: number,
	damage: number,
	range: number,
	windup: number,
	interval: number,
	speed: number,
	aggroRange: number,
	deathBlast: DeathBlast?,
	rank: ("MiniBoss" | "Boss")?,
	scale: number?,
	color: Color3,
}

local Enemies = {}

-- CollectionService tag of the spawn points built in Studio (US-027).
Enemies.SPAWN_TAG = "EnemySpawn"

-- Workspace attributes with the enemy numbers of the performance overlay (US-025).
Enemies.AWAKE_ATTRIBUTE = "EnemiesAwake"
Enemies.TOTAL_ATTRIBUTE = "EnemiesTotal"
Enemies.AI_TIME_ATTRIBUTE = "EnemyAiMsPerSecond"

-- The kind with this id, or nil.
function Enemies.kind(id: string): Kind?
	local kind = EnemiesConfig.KINDS[id]
	return if kind then kind :: any else nil
end

-- How much stronger than its base numbers an enemy of this tier is.
function Enemies.strength(tier: number): number
	return Items.attributeMultiplier(Zones.recommendedGearScore(tier))
end

-- Health and damage of an enemy of this kind, tier and elite flag.
function Enemies.stats(kind: Kind, tier: number, elite: boolean): (number, number)
	local strength = Enemies.strength(tier)
	local health = kind.health * strength * (if elite then EnemiesConfig.ELITE.health else 1)
	local damage = kind.damage * strength * (if elite then EnemiesConfig.ELITE.damage else 1)
	return health, damage
end

-- How many times a common enemy's fame this kind gives for its rank (US-043).
function Enemies.rankFameMultiplier(kind: Kind): number
	if kind.rank == "Boss" then
		return ProgressionConfig.BOSS_FAME_MULTIPLIER
	elseif kind.rank == "MiniBoss" then
		return ProgressionConfig.MINIBOSS_FAME_MULTIPLIER
	end
	return 1
end

-- The name shown above the enemy.
function Enemies.displayName(kind: Kind, elite: boolean): string
	return if elite then `{kind.name} de elite` else kind.name
end

-- Chance that a kill drops an item (Progression tab: common 5%, elite 25%).
function Enemies.itemChance(elite: boolean): number
	return if elite then LootConfig.ITEM_CHANCE_ELITE else LootConfig.ITEM_CHANCE_COMMON
end

-- Who earns a kill: everyone who dealt at least `minShare` of the damage in `contributions`.
function Enemies.credited<K>(contributions: { [K]: number }, minShare: number): { K }
	local total = 0
	for _, amount in contributions do
		total += amount
	end
	local list: { K } = {}
	if total <= 0 then
		return list
	end
	for who, amount in contributions do
		if amount / total >= minShare then
			table.insert(list, who)
		end
	end
	return list
end

return table.freeze(Enemies)
