--!strict
--[[
	LootBagService.luau
	Loot bags on the ground (US-026, US-040): an enemy that drops items, a full loot, or items that
	did not fit in a bag leave a bag where it happened, glowing with the color of its best item.
	For Config/Loot.BAG_PRIORITY_TIME seconds only its owners (who earned it) can open it; then
	anyone can. It disappears after BAG_LIFETIME seconds, with what is still inside. Opening it shows
	a loot window and the player takes what they want (LootContainerService, US-051).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local InterfaceConfig = require(ReplicatedStorage.Shared.Config.Interface)
local Items = require(ReplicatedStorage.Shared.Items)
local LootConfig = require(ReplicatedStorage.Shared.Config.Loot)
local LootContainerService = require(script.Parent.LootContainerService)

type ItemRecord = Items.ItemRecord

-- Game text (Portuguese) and the bag's look.
local BAG_NAME = "Bolsa"
local OPEN_TEXT = "Abrir"
local BAG_COLOR = Color3.fromRGB(110, 80, 50)
local BAG_SIZE = 1.6

local LootBagService = {}

local ownersOf: { [BasePart]: { [Player]: boolean } } = {}

local function bestRarity(items: { ItemRecord }): number
	local best = 1
	for _, record in items do
		best = math.max(best, record.rarity)
	end
	return best
end

-- Leaves a bag with `items` at `position`. `owners` are the players who earned it.
function LootBagService.drop(position: Vector3, items: { ItemRecord }, owners: { Player })
	if #items == 0 then
		return
	end
	local part = Instance.new("Part")
	part.Name = "LootBag"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(BAG_SIZE, BAG_SIZE, BAG_SIZE)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Color = BAG_COLOR

	local light = Instance.new("PointLight")
	light.Color = InterfaceConfig.RARITY_COLORS[bestRarity(items)] or Color3.new(1, 1, 1)
	light.Range = 8
	light.Brightness = 2
	light.Parent = part

	local ownerSet: { [Player]: boolean } = {}
	for _, owner in owners do
		ownerSet[owner] = true
	end
	ownersOf[part] = ownerSet
	local contents = table.clone(items)
	local freeAt = Workspace:GetServerTimeNow() + LootConfig.BAG_PRIORITY_TIME

	local container = LootContainerService.create({
		title = BAG_NAME,
		part = part,
		reach = LootConfig.BAG_REACH,
		itemsFor = function()
			return contents
		end,
		canOpen = function(player)
			if Workspace:GetServerTimeNow() < freeAt and not ownerSet[player] then
				return false, "NotYours"
			end
			return true, nil
		end,
		isEmpty = function()
			return #contents == 0
		end,
		onEmptied = function()
			part:Destroy()
		end,
	})

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = OPEN_TEXT
	prompt.ObjectText = BAG_NAME
	prompt.KeyboardKeyCode = InterfaceConfig.INTERACT_KEY
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = LootConfig.BAG_REACH
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	prompt.Triggered:Connect(function(player)
		LootContainerService.open(player, container)
	end)
	part.Destroying:Connect(function()
		ownersOf[part] = nil
	end)
	part.Parent = Workspace

	task.delay(LootConfig.BAG_LIFETIME, function()
		if part.Parent then
			part:Destroy()
		end
	end)
end

function LootBagService:Start()
	Players.PlayerRemoving:Connect(function(player)
		for _, owners in ownersOf do
			owners[player] = nil
		end
	end)
end

return LootBagService
