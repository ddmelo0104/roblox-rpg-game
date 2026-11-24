--!strict
--[[
	SplitChest.luau
	A chest whose items are split among a group of players (US-043, US-047, US-048): the dungeon and
	camp chests. The first time a player allowed to open it does, its items are rolled (Shared.Loot,
	with the zone's tier and luck and the boss chest chances) and dealt in turns, from a random
	player, among those sharing it: each one gets their own share. Then each player opens the chest
	and takes the items of their share in a loot window (LootContainerService, US-051). The chest
	goes away when every share is empty; a player who leaves the server loses their share.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InterfaceConfig = require(ReplicatedStorage.Shared.Config.Interface)
local Items = require(ReplicatedStorage.Shared.Items)
local Loot = require(ReplicatedStorage.Shared.Loot)
local LootConfig = require(ReplicatedStorage.Shared.Config.Loot)
local Zones = require(ReplicatedStorage.Shared.Zones)
local InventoryService = require(script.Parent.Services.InventoryService)
local LootContainerService = require(script.Parent.Services.LootContainerService)

type ItemRecord = Items.ItemRecord

export type Options = {
	parent: Instance,
	cframe: CFrame,
	count: number,
	zone: Zones.Zone,
	reach: number,
	-- Whether this player may be the first to open it (and so deal the items).
	canOpen: (player: Player) -> boolean,
	-- Who shares the items when `opener` opens it first (the opener is added if missing).
	sharers: (opener: Player) -> { Player },
}

-- Game text (Portuguese) and the chest's look.
local CHEST_NAME = "Baú"
local OPEN_TEXT = "Abrir"
local CHEST_COLOR = Color3.fromRGB(150, 110, 40)

local SplitChest = {}

local random = Random.new()

-- Creates a chest; returns its part (it is destroyed once every share is empty).
function SplitChest.spawn(options: Options): BasePart
	local chest = Instance.new("Part")
	chest.Name = "Chest"
	chest.Size = Vector3.new(4, 3, 3)
	chest.CFrame = options.cframe
	chest.Anchored = true
	chest.Color = CHEST_COLOR
	chest.Parent = options.parent

	local shares: { [Player]: { ItemRecord } } = {}
	local dealt = false

	local function deal(opener: Player)
		dealt = true
		local players = options.sharers(opener)
		if not table.find(players, opener) then
			table.insert(players, opener)
		end
		for i = #players, 2, -1 do
			local j = random:NextInteger(1, i)
			players[i], players[j] = players[j], players[i]
		end
		local zone = options.zone
		for i = 1, options.count do
			local itemId, tier, rarity =
				Loot.roll(zone.tier, zone.rules.luck, LootConfig.BOSS_CHEST_RARITY_WEIGHTS, random)
			local who = players[(i - 1) % #players + 1]
			shares[who] = shares[who] or {}
			table.insert(shares[who], InventoryService.createItem(itemId, tier, rarity))
		end
	end

	local container = LootContainerService.create({
		title = CHEST_NAME,
		part = chest,
		reach = options.reach,
		itemsFor = function(player)
			return shares[player]
		end,
		canOpen = function(player)
			local share = shares[player]
			if not share or #share == 0 then
				return false, "NothingForYou"
			end
			return true, nil
		end,
		isEmpty = function()
			if not dealt then
				return false
			end
			for _, share in shares do
				if #share > 0 then
					return false
				end
			end
			return true
		end,
		onEmptied = function()
			chest:Destroy()
		end,
	})

	-- A player who leaves the server loses their share; the chest goes away if nothing is left.
	local leaving = Players.PlayerRemoving:Connect(function(player)
		if shares[player] then
			shares[player] = nil
			if container.isEmpty() then
				chest:Destroy()
			end
		end
	end)
	chest.Destroying:Connect(function()
		leaving:Disconnect()
	end)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = OPEN_TEXT
	prompt.ObjectText = CHEST_NAME
	prompt.KeyboardKeyCode = InterfaceConfig.INTERACT_KEY
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = options.reach
	prompt.RequiresLineOfSight = false
	prompt.Parent = chest
	prompt.Triggered:Connect(function(player)
		if not dealt and options.canOpen(player) then
			deal(player)
			if container.isEmpty() then
				chest:Destroy() -- nothing was rolled (a chest of 0 items)
				return
			end
		end
		LootContainerService.open(player, container)
	end)
	return chest
end

return table.freeze(SplitChest)
