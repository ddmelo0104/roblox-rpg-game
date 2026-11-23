--!strict
--[[
	InventoryService.luau
	Each player's items (US-017, US-018, ADR-006): the bag and what the character wears, as records
	whose uid only this service creates. Every move takes an item out of one place and puts it in the
	other inside a single function call, without yielding, so an item never exists in two places
	(rule 6 of CLAUDE.md). After every change, the client gets a copy (InventoryUpdate) and the
	listeners run (StatsService). The client asks to equip by uid and to unequip by slot.
	Everything lives in memory until the profile is saved (EP-006).
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local ItemsConfig = require(ReplicatedStorage.Shared.Config.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Validate = require(ReplicatedStorage.Shared.Validate)
local Network = require(script.Parent.Parent.Network)

type ItemRecord = Items.ItemRecord

type Inventory = {
	bag: { ItemRecord },
	equipped: Items.Equipped,
}

-- A uid is a GUID: 36 characters.
local MAX_UID_LENGTH = 64

local InventoryService = {}

local inventories: { [Player]: Inventory } = {}
local listeners: { (player: Player) -> () } = {}

local updateEvent = Remotes.event("InventoryUpdate")
local noticeEvent = Remotes.event("Notice")

local function copyRecord(record: ItemRecord): ItemRecord
	return {
		uid = record.uid,
		itemId = record.itemId,
		tier = record.tier,
		rarity = record.rarity,
		durability = record.durability,
	}
end

-- Sends the player a copy of the bag and the equipment, then runs the listeners.
local function changed(player: Player)
	local inventory = inventories[player]
	if not inventory then
		return
	end
	local bag: { ItemRecord } = {}
	for index, record in inventory.bag do
		bag[index] = copyRecord(record)
	end
	local equipped: Items.Equipped = {}
	for slot, record in inventory.equipped do
		equipped[slot] = copyRecord(record)
	end
	updateEvent:FireClient(player, bag, equipped)
	for _, listener in listeners do
		listener(player)
	end
end

local function findInBag(inventory: Inventory, uid: string): number?
	for index, record in inventory.bag do
		if record.uid == uid then
			return index
		end
	end
	return nil
end

-- Creates a new item record with a fresh uid. Only the server calls this (ADR-006).
function InventoryService.createItem(itemId: string, tier: number, rarity: number): ItemRecord
	assert(Items.definition(itemId), `unknown item: {itemId}`)
	return {
		uid = HttpService:GenerateGUID(false),
		itemId = itemId,
		tier = tier,
		rarity = rarity,
		durability = 100,
	}
end

-- Puts an item in the player's bag. Returns false, and keeps nothing, if the bag is full.
function InventoryService.give(player: Player, record: ItemRecord): boolean
	local inventory = inventories[player]
	if not inventory or #inventory.bag >= ItemsConfig.INVENTORY_SIZE then
		return false
	end
	table.insert(inventory.bag, record)
	changed(player)
	return true
end

-- What the player wears, by slot. Read only: other services must not change it.
function InventoryService.equipped(player: Player): Items.Equipped
	local inventory = inventories[player]
	return if inventory then inventory.equipped else {}
end

-- Runs `listener(player)` after every change of any player's inventory.
function InventoryService.onChanged(listener: (player: Player) -> ())
	table.insert(listeners, listener)
end

-- Moves the bag item `uid` to its slot; what was in the slot takes its place in the bag.
local function equip(player: Player, uid: string)
	local inventory = inventories[player]
	local index = if inventory then findInBag(inventory, uid) else nil
	if not inventory or not index then
		warn(`[Inventory] {player.Name} asked to equip an item that is not in the bag`)
		return
	end
	local record = inventory.bag[index]
	local definition = Items.definition(record.itemId)
	if not definition then
		return
	end
	-- One move, no yields: the item leaves the bag and the old one takes its place.
	local previous = inventory.equipped[definition.slot]
	if previous then
		inventory.bag[index] = previous
	else
		table.remove(inventory.bag, index)
	end
	inventory.equipped[definition.slot] = record
	changed(player)
end

-- Moves what the player wears in `slot` back to the bag, if there is room.
local function unequip(player: Player, slot: string)
	local inventory = inventories[player]
	local record = if inventory then inventory.equipped[slot] else nil
	if not inventory or not record then
		return
	end
	if #inventory.bag >= ItemsConfig.INVENTORY_SIZE then
		noticeEvent:FireClient(player, "Inventário", "BagFull")
		return
	end
	inventory.equipped[slot] = nil
	table.insert(inventory.bag, record)
	changed(player)
end

-- Every new player gets the starter kit, equipped (T1 Common), and an empty bag.
local function onPlayerAdded(player: Player)
	local inventory: Inventory = { bag = {}, equipped = {} }
	for _, itemId in ItemsConfig.STARTER_KIT do
		local definition = Items.definition(itemId)
		if definition then
			inventory.equipped[definition.slot] = InventoryService.createItem(itemId, ItemsConfig.MIN_TIER, 1)
		end
	end
	inventories[player] = inventory
	changed(player)
end

function InventoryService:Start()
	Network.onReceive("RequestEquip", function(uid)
		return Validate.shortString(uid, MAX_UID_LENGTH)
	end, equip)
	Network.onReceive("RequestUnequip", function(slot)
		return Validate.oneOf(slot, ItemsConfig.SLOTS)
	end, unequip)

	-- InventoryUpdate and Notice are server notices only.
	updateEvent.OnServerEvent:Connect(function() end)
	noticeEvent.OnServerEvent:Connect(function() end)

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		inventories[player] = nil
	end)
end

return InventoryService
