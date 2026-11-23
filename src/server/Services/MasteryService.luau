--!strict
--[[
	MasteryService.luau
	Fame, item specialization and line mastery of each player (EP-005, Progression tab). The fame of
	a kill (US-029) goes to what the player wears when it lands: the weapon gets 100%, the chest 50%,
	the helmet and the boots 25% each, and each line's mastery gets the sum of its items' shares
	(Shared.Mastery). The levels raise the GS (US-030: StatsService listens to `onChanged`) and decide
	which tiers a player can wear (US-031: an equip rule of InventoryService). The client gets a copy
	of the totals and of each gain (ProgressUpdate), for the fame pop-up and the mastery screen.
	Nothing is saved yet: the profile of EP-006 will keep it.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Mastery = require(ReplicatedStorage.Shared.Mastery)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local InventoryService = require(script.Parent.InventoryService)

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

local function onPlayerAdded(player: Player)
	progressOf[player] = Mastery.newProgress()
	send(player, nil)
end

function MasteryService:Start()
	InventoryService.addEquipRule(masteryRule)
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		if not progressOf[player] then
			onPlayerAdded(player)
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		progressOf[player] = nil
	end)
end

return MasteryService
