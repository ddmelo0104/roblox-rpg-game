--!strict
--[[
	MasteryService.luau
	Fame, item specialization and line mastery of each player (EP-005, Progression tab). The fame of
	a kill (US-029) goes to what the player wears when it lands: the weapon gets 100%, the chest 50%,
	the helmet and the boots 25% each, and each line's mastery gets the sum of its items' shares
	(Shared.Mastery). The levels raise the GS (US-030: StatsService listens to `onChanged`) and decide
	which tiers a player can wear (US-031: an equip rule of InventoryService). The client gets a copy
	of the totals and of each gain (ProgressUpdate), for the fame pop-up and the mastery screen.
	The fame totals are a section of the saved profile (ProfileService, US-033).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Mastery = require(ReplicatedStorage.Shared.Mastery)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local InventoryService = require(script.Parent.InventoryService)
local ProfileService = require(script.Parent.ProfileService)

-- A level reached with a gain, for the pop-up: an item kind's specialization or a line's mastery.
export type LevelUp = { kind: "Item" | "Line", id: string, level: number }

-- One gain, as the client gets it: the fame, the weapon that got it (if any) and the new levels.
export type Gain = { amount: number, weaponId: string?, levelUps: { LevelUp } }

local MasteryService = {}

local progressOf: { [Player]: Mastery.Progress } = {}
local listeners: { (player: Player) -> () } = {}
local updateEvent = Remotes.event("ProgressUpdate")

local function send(player: Player, gain: Gain?)
	updateEvent:FireClient(player, progressOf[player], gain)
end

-- The player's fame totals. Read only: only this service changes them.
function MasteryService.progress(player: Player): Mastery.Progress
	return progressOf[player] or Mastery.newProgress()
end

-- The levels of a worn item of the player, for the GS.
function MasteryService.levelsOf(player: Player): Items.LevelsOf
	return Mastery.levelsOf(MasteryService.progress(player))
end

-- Runs `listener(player)` when a specialization or a mastery level of the player goes up.
function MasteryService.onChanged(listener: (player: Player) -> ())
	table.insert(listeners, listener)
end

-- Gives `amount` of fame to the player, split over what they wear right now.
function MasteryService.award(player: Player, amount: number)
	local progress = progressOf[player]
	if not progress or amount <= 0 then
		return
	end
	local equipped = InventoryService.equipped(player)
	local shares = Mastery.split(amount, equipped)

	-- The levels before and after this gain show what went up.
	local before: { [string]: number } = {}
	for _, share in shares do
		before["Item:" .. share.itemId] = Mastery.specialization(progress, share.itemId)
		before["Line:" .. share.line] = Mastery.mastery(progress, share.line)
	end
	Mastery.add(progress, amount, equipped)

	local levelUps: { LevelUp } = {}
	local seen: { [string]: boolean } = {}
	for _, share in shares do
		local itemLevel = Mastery.specialization(progress, share.itemId)
		if itemLevel > before["Item:" .. share.itemId] and not seen["Item:" .. share.itemId] then
			seen["Item:" .. share.itemId] = true
			table.insert(levelUps, { kind = "Item", id = share.itemId, level = itemLevel })
		end
		local lineLevel = Mastery.mastery(progress, share.line)
		if lineLevel > before["Line:" .. share.line] and not seen["Line:" .. share.line] then
			seen["Line:" .. share.line] = true
			table.insert(levelUps, { kind = "Line", id = share.line, level = lineLevel })
		end
	end

	local weapon = equipped.Weapon
	send(player, { amount = amount, weaponId = if weapon then weapon.itemId else nil, levelUps = levelUps })
	if #levelUps > 0 then
		for _, listener in listeners do
			task.spawn(listener, player)
		end
	end
end

-- The equip rule of US-031: the line's mastery must reach what the item's tier needs.
local function masteryRule(player: Player, record: Items.ItemRecord): string?
	local canWear, required, line = Mastery.canWear(MasteryService.progress(player), record)
	if canWear then
		return nil
	end
	return `requer {Mastery.lineName(line)} {required}`
end

-- Only positive numbers under text keys come back from a saved table.
local function checkedTotals(saved: any): { [string]: number }
	local totals: { [string]: number } = {}
	if type(saved) == "table" then
		for key, value in saved do
			if type(key) == "string" and type(value) == "number" and value > 0 and value < math.huge then
				totals[key] = value
			end
		end
	end
	return totals
end

-- The profile section: the fame totals load, save and are released with the profile.
local function loadSection(player: Player, saved: any)
	local progress = Mastery.newProgress()
	if type(saved) == "table" then
		progress.items = checkedTotals(saved.items)
		progress.lines = checkedTotals(saved.lines)
	end
	progressOf[player] = progress
	send(player, nil)
	for _, listener in listeners do
		task.spawn(listener, player) -- the saved levels count for the GS at once
	end
end

local function saveSection(player: Player): any
	return progressOf[player]
end

local function releaseSection(player: Player)
	progressOf[player] = nil
end

function MasteryService:Init()
	ProfileService.addSection("mastery", loadSection, saveSection, releaseSection)
	InventoryService.addEquipRule(masteryRule)
end

return MasteryService
