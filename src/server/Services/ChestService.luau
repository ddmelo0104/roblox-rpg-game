--!strict
--[[
	ChestService.luau
	Loot chests for testing (US-020). Every part tagged "LootChest" gets a ProximityPrompt; opening it
	rolls an item with Shared.Loot (the chest's Tier and Luck attributes) into the player's own share
	of the chest, and the loot window shows it to be taken (LootContainerService, US-051). A new item
	is rolled when the share is empty, after a short wait. If the place has no chest, a test chest
	appears next to the spawn, like the training dummies.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local InterfaceConfig = require(ReplicatedStorage.Shared.Config.Interface)
local Items = require(ReplicatedStorage.Shared.Items)
local Loot = require(ReplicatedStorage.Shared.Loot)
local LootConfig = require(ReplicatedStorage.Shared.Config.Loot)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local InventoryService = require(script.Parent.InventoryService)
local LootContainerService = require(script.Parent.LootContainerService)

local TAG = "LootChest"

-- Game text (Portuguese) and the test chest's look.
local CHEST_NAME = "Baú"
local TEST_CHEST_TEXT = "Baú de teste"
local OPEN_TEXT = "Abrir"
local CHEST_COLOR = Color3.fromRGB(120, 80, 40)

local ChestService = {}

local random = Random.new()
local lastOpened: { [Player]: number } = {}

-- The test chest gives each player a share of one item at a time: opening it rolls a new item when
-- the player's share is empty, and the loot window shows it (US-051).
local shares: { [Player]: { Items.ItemRecord } } = {}

local function notify(player: Player, reason: string)
	Remotes.event("Notice"):FireClient(player, CHEST_NAME, reason)
end

-- Rolls a new item into the player's share; false while the short wait between items runs.
local function rollFor(player: Player, chest: BasePart): boolean
	local now = os.clock()
	if now - (lastOpened[player] or 0) < LootConfig.TEST_CHEST_COOLDOWN then
		return false
	end
	lastOpened[player] = now
	local tier = chest:GetAttribute("Tier")
	local luck = chest:GetAttribute("Luck")
	local itemId, rolledTier, rarity = Loot.roll(
		if typeof(tier) == "number" then tier else LootConfig.TEST_CHEST_TIER,
		if typeof(luck) == "number" then luck else LootConfig.TEST_CHEST_LUCK,
		LootConfig.ENEMY_RARITY_WEIGHTS,
		random
	)
	shares[player] = { InventoryService.createItem(itemId, rolledTier, rarity) }
	return true
end

local function setUpChest(chest: Instance)
	if not chest:IsA("BasePart") or chest:FindFirstChildOfClass("ProximityPrompt") then
		return
	end
	local container = LootContainerService.create({
		title = CHEST_NAME,
		part = chest,
		reach = LootConfig.CHEST_REACH,
		itemsFor = function(player)
			return shares[player]
		end,
		canOpen = function()
			return true, nil
		end,
		isEmpty = function()
			return false -- the test chest never runs out
		end,
		onEmptied = nil,
	})
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = OPEN_TEXT
	prompt.ObjectText = TEST_CHEST_TEXT
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = LootConfig.CHEST_REACH
	prompt.KeyboardKeyCode = InterfaceConfig.INTERACT_KEY
	prompt.Parent = chest
	prompt.Triggered:Connect(function(player)
		local share = shares[player]
		if (not share or #share == 0) and not rollFor(player, chest) then
			notify(player, "OnCooldown")
			return
		end
		LootContainerService.open(player, container)
	end)
end

-- The test chest: to the left of the spawn, so it is not in the way of the dummies.
local function createTestChest()
	local spawnLocation = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	local base = if spawnLocation and spawnLocation:IsA("BasePart")
		then spawnLocation.CFrame * CFrame.new(-10, 2, -6)
		else CFrame.new(-10, 2, -6)
	local chest = Instance.new("Part")
	chest.Name = "TestChest"
	chest.Size = Vector3.new(3, 2.5, 2)
	chest.CFrame = base
	chest.Anchored = true
	chest.Color = CHEST_COLOR
	chest:SetAttribute("Tier", LootConfig.TEST_CHEST_TIER)
	chest:SetAttribute("Luck", LootConfig.TEST_CHEST_LUCK)
	CollectionService:AddTag(chest, TAG)
	chest.Parent = Workspace
end

function ChestService:Start()
	CollectionService:GetInstanceAddedSignal(TAG):Connect(setUpChest)
	for _, chest in CollectionService:GetTagged(TAG) do
		setUpChest(chest)
	end
	if #CollectionService:GetTagged(TAG) == 0 then
		createTestChest()
	end
	Players.PlayerRemoving:Connect(function(player)
		lastOpened[player] = nil
		shares[player] = nil
	end)
end

return ChestService
