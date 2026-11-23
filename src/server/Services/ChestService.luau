--!strict
--[[
	ChestService.luau
	Loot chests (US-020). Every part tagged "LootChest" gets a ProximityPrompt; opening it rolls an
	item with Shared.Loot (the chest's Tier and Luck attributes) and puts it in the player's bag. The
	server checks the distance and a short wait between openings. If the place has no chest, a test
	chest appears next to the spawn, like the training dummies. Dungeon chests (EP-010) will reuse
	this.
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

local TAG = "LootChest"

-- Game text (Portuguese) and the test chest's look.
local CHEST_NAME = "Baú"
local TEST_CHEST_TEXT = "Baú de teste"
local OPEN_TEXT = "Abrir"
local CHEST_COLOR = Color3.fromRGB(120, 80, 40)

local ChestService = {}

local random = Random.new()
local lastOpened: { [Player]: number } = {}

local function notify(player: Player, reason: string)
	Remotes.event("Notice"):FireClient(player, CHEST_NAME, reason)
end

local function open(player: Player, chest: BasePart)
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not root or not root:IsA("BasePart") or (root.Position - chest.Position).Magnitude > LootConfig.CHEST_REACH then
		notify(player, "TooFar")
		return
	end
	local now = os.clock()
	if now - (lastOpened[player] or 0) < LootConfig.TEST_CHEST_COOLDOWN then
		return
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
	local record = InventoryService.createItem(itemId, rolledTier, rarity)
	if InventoryService.give(player, record) then
		notify(player, Items.displayName(record))
	else
		notify(player, "BagFull")
	end
end

local function setUpChest(chest: Instance)
	if not chest:IsA("BasePart") or chest:FindFirstChildOfClass("ProximityPrompt") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = OPEN_TEXT
	prompt.ObjectText = TEST_CHEST_TEXT
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = LootConfig.CHEST_REACH
	prompt.KeyboardKeyCode = InterfaceConfig.INTERACT_KEY
	prompt.Parent = chest
	prompt.Triggered:Connect(function(player)
		open(player, chest)
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
	end)
end

return ChestService
