--!strict
--[[
	Mastery.luau
	Pure rules of fame, item specialization and line mastery (EP-005, Progression tab), for the
	server and the client:
	- the fame of a kill, and how a gain splits over what the player wears (US-029);
	- the level, 0 to 100, of a fame total, on the curve FAME_CURVE × level³ (US-029);
	- the levels of a worn item, for its GS (US-030, through Shared.Items);
	- the line mastery needed to wear each tier (US-031).
	A player's fame totals (`Progress`) live on the server (MasteryService); the client gets a copy.
]]

local Items = require(script.Parent.Items)
local ItemsConfig = require(script.Parent.Config.Items)
local ProgressionConfig = require(script.Parent.Config.Progression)

export type Progress = {
	-- Fame total of each item kind (its specialization) and of each line (its mastery).
	items: { [string]: number },
	lines: { [string]: number },
}

-- What one worn item got from a gain.
export type Share = { itemId: string, line: string, amount: number }

local Mastery = {}

function Mastery.newProgress(): Progress
	return { items = {}, lines = {} }
end

-- Total fame needed to reach `level`.
function Mastery.fameForLevel(level: number): number
	return ProgressionConfig.FAME_CURVE * level ^ 3
end

-- The level (0 to MAX_LEVEL) of a fame total.
function Mastery.level(fame: number): number
	local maxLevel = ProgressionConfig.MAX_LEVEL
	local level = math.clamp(math.floor((math.max(fame, 0) / ProgressionConfig.FAME_CURVE) ^ (1 / 3)), 0, maxLevel)
	-- The cube root can land a hair off a whole level; the exact totals settle it.
	while level < maxLevel and Mastery.fameForLevel(level + 1) <= fame do
		level += 1
	end
	while level > 0 and Mastery.fameForLevel(level) > fame do
		level -= 1
	end
	return level
end

-- Fame of a kill: KILL_FAME_BASE × KILL_FAME_GROWTH^(tier − 1), ×3 for an elite, × the zone's
-- multiplier.
function Mastery.killFame(tier: number, elite: boolean, zoneMultiplier: number): number
	local base = ProgressionConfig.KILL_FAME_BASE * ProgressionConfig.KILL_FAME_GROWTH ^ (tier - 1)
	return base * (if elite then ProgressionConfig.ELITE_FAME_MULTIPLIER else 1) * zoneMultiplier
end

-- How a gain of `amount` splits over what is worn: each item gets its slot's share.
function Mastery.split(amount: number, equipped: Items.Equipped): { Share }
	local slotShares = ProgressionConfig.FAME_SLOT_SHARES :: any
	local shares: { Share } = {}
	for _, slot in ItemsConfig.SLOTS do
		local record = equipped[slot]
		local definition = if record then Items.definition(record.itemId) else nil
		local fraction = slotShares[slot]
		if record and definition and fraction then
			table.insert(shares, { itemId = record.itemId, line = definition.line, amount = amount * fraction })
		end
	end
	return shares
end

-- Adds a gain of `amount` to `progress`, split over what is worn. Returns the shares.
function Mastery.add(progress: Progress, amount: number, equipped: Items.Equipped): { Share }
	local shares = Mastery.split(amount, equipped)
	for _, share in shares do
		progress.items[share.itemId] = (progress.items[share.itemId] or 0) + share.amount
		progress.lines[share.line] = (progress.lines[share.line] or 0) + share.amount
	end
	return shares
end

-- Specialization level of an item kind.
function Mastery.specialization(progress: Progress, itemId: string): number
	return Mastery.level(progress.items[itemId] or 0)
end

-- Mastery level of a line.
function Mastery.mastery(progress: Progress, line: string): number
	return Mastery.level(progress.lines[line] or 0)
end

-- The levels of a worn item, in the form Shared.Items uses for the GS.
function Mastery.levelsOf(progress: Progress): Items.LevelsOf
	return function(record)
		local definition = Items.definition(record.itemId)
		local line = if definition then definition.line else ""
		return Mastery.specialization(progress, record.itemId), Mastery.mastery(progress, line)
	end
end

-- Line mastery needed to wear an item of `tier`.
function Mastery.requiredMastery(tier: number): number
	return ProgressionConfig.TIER_MASTERY[tier] or ProgressionConfig.MAX_LEVEL
end

-- Whether the player can wear `record`, the mastery its tier needs and its line.
function Mastery.canWear(progress: Progress, record: Items.ItemRecord): (boolean, number, string)
	local definition = Items.definition(record.itemId)
	local line = if definition then definition.line else ""
	local required = Mastery.requiredMastery(record.tier)
	return Mastery.mastery(progress, line) >= required, required, line
end

-- The name of a line shown to players.
function Mastery.lineName(line: string): string
	return (ItemsConfig.LINE_NAMES :: any)[line] or line
end

return table.freeze(Mastery)
