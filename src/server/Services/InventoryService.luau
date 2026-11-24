--!strict
--[[
	InventoryService.luau
	Each player's items (US-017, US-018, ADR-006): the bag and what the character wears, as records
	whose uid only this service creates. Every move takes an item out of one place and puts it in the
	other inside a single function call, without yielding, so an item never exists in two places
	(rule 6 of CLAUDE.md). After every change, the client gets a copy (InventoryUpdate) and the
	listeners run (StatsService). The client asks to equip by uid and to unequip by slot.
	The inventory is a section of the saved profile (ProfileService, US-033): it loads from there,
	or starts with the starter kit for a new player, and a loaded profile is checked so no saved
	uid appears twice.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local ItemsConfig = require(ReplicatedStorage.Shared.Config.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Validate = require(ReplicatedStorage.Shared.Validate)
local Network = require(script.Parent.Parent.Network)
local ProfileService = require(script.Parent.ProfileService)

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
local equipRules: { (player: Player, record: ItemRecord) -> string? } = {}
local equippedListeners: { (player: Player, record: ItemRecord) -> () } = {}

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

-- Takes every worn and carried item out of the player's inventory, in one step with no yields, and
-- returns them (the full loot of US-040). The player is left with nothing.
function InventoryService.takeAll(player: Player): { ItemRecord }
	local inventory = inventories[player]
	if not inventory then
		return {}
	end
	local taken: { ItemRecord } = {}
	for _, slot in ItemsConfig.SLOTS do
		local record = inventory.equipped[slot]
		if record then
			table.insert(taken, record)
			inventory.equipped[slot] = nil
		end
	end
	for _, record in inventory.bag do
		table.insert(taken, record)
	end
	inventory.bag = {}
	changed(player)
	return taken
end

-- Equips a new starter item in every empty slot (the restart kit after a full loot, US-040).
function InventoryService.giveRestartKit(player: Player)
	local inventory = inventories[player]
	if not inventory then
		return
	end
	for _, itemId in ItemsConfig.STARTER_KIT do
		local definition = Items.definition(itemId)
		if definition and not inventory.equipped[definition.slot] then
			inventory.equipped[definition.slot] = InventoryService.createItem(itemId, ItemsConfig.MIN_TIER, 1)
		end
	end
	changed(player)
end

-- Takes `points` of durability from every worn item (getting up from a knockdown, US-038).
function InventoryService.wearDown(player: Player, points: number)
	local inventory = inventories[player]
	if not inventory then
		return
	end
	for _, record in inventory.equipped do
		record.durability = math.max(0, record.durability - points)
	end
	changed(player)
end

-- Runs `listener(player, record)` after the player equips an item (the tutorial, US-045).
function InventoryService.onEquipped(listener: (player: Player, record: ItemRecord) -> ())
	table.insert(equippedListeners, listener)
end

-- Adds a check to every equip: `rule` returns the text to show the player when they cannot wear the
-- item (the mastery a tier needs, US-031), or nil. Rules must not yield.
function InventoryService.addEquipRule(rule: (player: Player, record: ItemRecord) -> string?)
	table.insert(equipRules, rule)
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
	for _, rule in equipRules do
		local refusal = rule(player, record)
		if refusal then
			noticeEvent:FireClient(player, "Inventário", refusal)
			return
		end
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
	for _, listener in equippedListeners do
		task.spawn(listener, player, record)
	end
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

-- A new player gets the starter kit, equipped (T1 Common), and an empty bag.
local function starterInventory(): Inventory
	local inventory: Inventory = { bag = {}, equipped = {} }
	for _, itemId in ItemsConfig.STARTER_KIT do
		local definition = Items.definition(itemId)
		if definition then
			inventory.equipped[definition.slot] = InventoryService.createItem(itemId, ItemsConfig.MIN_TIER, 1)
		end
	end
	return inventory
end

-- A saved record, checked: an item that still exists in the catalog, with a uid not seen yet.
-- Anything else is dropped with a warning (it should never happen).
local function checkedRecord(saved: any, seen: { [string]: boolean }, player: Player): ItemRecord?
	if type(saved) ~= "table" or type(saved.uid) ~= "string" or type(saved.itemId) ~= "string" then
		warn(`[Inventory] {player.Name}: dropped a malformed saved item`)
		return nil
	end
	if seen[saved.uid] then
		warn(`[Inventory] {player.Name}: dropped a second copy of item {saved.uid}`)
		return nil
	end
	if not Items.definition(saved.itemId) then
		warn(`[Inventory] {player.Name}: dropped {saved.uid}, unknown item {saved.itemId}`)
		return nil
	end
	seen[saved.uid] = true
	return {
		uid = saved.uid,
		itemId = saved.itemId,
		tier = math.clamp(tonumber(saved.tier) or ItemsConfig.MIN_TIER, ItemsConfig.MIN_TIER, ItemsConfig.MAX_TIER),
		rarity = math.clamp(tonumber(saved.rarity) or 1, 1, #ItemsConfig.RARITY_NAMES),
		durability = math.clamp(tonumber(saved.durability) or 100, 0, 100),
	}
end

-- The profile section's load: the saved inventory, checked, or the starter kit.
local function loadSection(player: Player, saved: any)
	local inventory: Inventory
	if type(saved) == "table" and type(saved.bag) == "table" and type(saved.equipped) == "table" then
		inventory = { bag = {}, equipped = {} }
		local seen: { [string]: boolean } = {}
		for _, slot in ItemsConfig.SLOTS do
			local record = checkedRecord(saved.equipped[slot], seen, player)
			if record and Items.definition(record.itemId).slot == slot then
				inventory.equipped[slot] = record
			elseif record then
				table.insert(inventory.bag, record) -- in the wrong slot: back to the bag
			end
		end
		for _, savedRecord in saved.bag do
			local record = checkedRecord(savedRecord, seen, player)
			if record then
				table.insert(inventory.bag, record)
			end
		end
	else
		inventory = starterInventory()
	end
	inventories[player] = inventory
	changed(player)
end

-- The profile section's save: the bag and what is worn.
local function saveSection(player: Player): any
	local inventory = inventories[player]
	if not inventory then
		return nil
	end
	return { bag = inventory.bag, equipped = inventory.equipped }
end

-- The profile section's release: the player left and their last save has its copy.
local function releaseSection(player: Player)
	inventories[player] = nil
end

function InventoryService:Init()
	ProfileService.addSection("inventory", loadSection, saveSection, releaseSection)
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
end

return InventoryService
