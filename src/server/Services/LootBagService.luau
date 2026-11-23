--!strict
--[[
	LootBagService.luau
	Loot bags on the ground (US-026). An enemy that drops items leaves a bag where it fell, glowing
	with the color of its best item. For Config/Loot.BAG_PRIORITY_TIME seconds only the players who
	earned the kill can take it; then anyone can. It disappears after BAG_LIFETIME seconds, with what
	is still inside. Taking it moves the items to the player's bag in one call with no yields, so an
	item is always in one place only (rule 6, ADR-006); what does not fit stays in the loot bag.
	The bags of a full loot (EP-009) will reuse this.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local InterfaceConfig = require(ReplicatedStorage.Shared.Config.Interface)
local Items = require(ReplicatedStorage.Shared.Items)
local LootConfig = require(ReplicatedStorage.Shared.Config.Loot)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local InventoryService = require(script.Parent.InventoryService)

type ItemRecord = Items.ItemRecord

type Bag = {
	part: BasePart,
	items: { ItemRecord },
	owners: { [Player]: boolean },
	-- Server time from which anyone can take it.
	freeAt: number,
}

-- Game text (Portuguese) and the bag's look.
local BAG_NAME = "Bolsa"
local TAKE_TEXT = "Pegar"
local BAG_COLOR = Color3.fromRGB(110, 80, 50)
local BAG_SIZE = 1.6

local LootBagService = {}

local bags: { [BasePart]: Bag } = {}

local function notify(player: Player, reason: string)
	Remotes.event("Notice"):FireClient(player, BAG_NAME, reason)
end

local function remove(bag: Bag)
	bags[bag.part] = nil
	bag.part:Destroy()
end

local function bestRarity(items: { ItemRecord }): number
	local best = 1
	for _, record in items do
		best = math.max(best, record.rarity)
	end
	return best
end

local function take(player: Player, bag: Bag)
	if not bags[bag.part] then
		return -- already emptied or gone
	end
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not root or not root:IsA("BasePart") or (root.Position - bag.part.Position).Magnitude > LootConfig.BAG_REACH then
		notify(player, "TooFar")
		return
	end
	if Workspace:GetServerTimeNow() < bag.freeAt and not bag.owners[player] then
		notify(player, "NotYours")
		return
	end

	-- No yields from here on: each item leaves the loot bag in the same step it enters the player's.
	local remaining: { ItemRecord } = {}
	for _, record in bag.items do
		if InventoryService.give(player, record) then
			notify(player, Items.displayName(record))
		else
			table.insert(remaining, record)
		end
	end
	bag.items = remaining
	if #remaining == 0 then
		remove(bag)
	else
		notify(player, "BagFull")
	end
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
	part.Color = BAG_COLOR

	local light = Instance.new("PointLight")
	light.Color = InterfaceConfig.RARITY_COLORS[bestRarity(items)] or Color3.new(1, 1, 1)
	light.Range = 8
	light.Brightness = 2
	light.Parent = part

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = TAKE_TEXT
	prompt.ObjectText = BAG_NAME
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = LootConfig.BAG_REACH
	prompt.KeyboardKeyCode = InterfaceConfig.INTERACT_KEY
	prompt.RequiresLineOfSight = false
	prompt.Parent = part

	local ownerSet: { [Player]: boolean } = {}
	for _, owner in owners do
		ownerSet[owner] = true
	end
	local bag: Bag = {
		part = part,
		items = table.clone(items),
		owners = ownerSet,
		freeAt = Workspace:GetServerTimeNow() + LootConfig.BAG_PRIORITY_TIME,
	}
	bags[part] = bag
	prompt.Triggered:Connect(function(player)
		take(player, bag)
	end)
	part.Parent = Workspace

	task.delay(LootConfig.BAG_LIFETIME, function()
		if bags[part] then
			remove(bag)
		end
	end)
end

function LootBagService:Start()
	Players.PlayerRemoving:Connect(function(player)
		for _, bag in bags do
			bag.owners[player] = nil
		end
	end)
end

return LootBagService
