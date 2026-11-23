--!strict
--[[
	SplitChest.luau
	A chest whose items are split among a group of players (US-043, US-047, US-048): the dungeon
	chests and the camp chests. The first player allowed to open it rolls its items (Shared.Loot,
	with the zone's tier and luck and the boss chest chances) and they are dealt in turns, from a
	random player, among those sharing it; what does not fit in a bag goes to a loot bag for that
	player. A chest opens only once.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InterfaceConfig = require(ReplicatedStorage.Shared.Config.Interface)
local Items = require(ReplicatedStorage.Shared.Items)
local Loot = require(ReplicatedStorage.Shared.Loot)
local LootConfig = require(ReplicatedStorage.Shared.Config.Loot)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Zones = require(ReplicatedStorage.Shared.Zones)
local InventoryService = require(script.Parent.Services.InventoryService)
local LootBagService = require(script.Parent.Services.LootBagService)

export type Options = {
	parent: Instance,
	cframe: CFrame,
	count: number,
	zone: Zones.Zone,
	reach: number,
	-- Whether this player may open it.
	canOpen: (player: Player) -> boolean,
	-- Who shares the items when `opener` opens it (the opener is added if missing).
	sharers: (opener: Player) -> { Player },
}

-- Game text (Portuguese) and the chest's look.
local CHEST_NAME = "Baú"
local OPEN_TEXT = "Abrir"
local CHEST_COLOR = Color3.fromRGB(150, 110, 40)

local SplitChest = {}

local random = Random.new()

local function notify(player: Player, reason: string)
	Remotes.event("Notice"):FireClient(player, CHEST_NAME, reason)
end

-- Creates a chest; returns its part (it is destroyed once opened).
function SplitChest.spawn(options: Options): BasePart
	local chest = Instance.new("Part")
	chest.Name = "Chest"
	chest.Size = Vector3.new(4, 3, 3)
	chest.CFrame = options.cframe
	chest.Anchored = true
	chest.Color = CHEST_COLOR
	chest.Parent = options.parent

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = OPEN_TEXT
	prompt.ObjectText = CHEST_NAME
	prompt.KeyboardKeyCode = InterfaceConfig.INTERACT_KEY
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = options.reach
	prompt.RequiresLineOfSight = false
	prompt.Parent = chest

	local opened = false
	prompt.Triggered:Connect(function(player)
		if opened or not options.canOpen(player) then
			return
		end
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if not root or not root:IsA("BasePart") or (root.Position - chest.Position).Magnitude > options.reach + 2 then
			notify(player, "TooFar")
			return
		end
		opened = true
		local players = options.sharers(player)
		if not table.find(players, player) then
			table.insert(players, player)
		end
		for i = #players, 2, -1 do
			local j = random:NextInteger(1, i)
			players[i], players[j] = players[j], players[i]
		end
		local zone = options.zone
		for i = 1, options.count do
			local itemId, tier, rarity =
				Loot.roll(zone.tier, zone.rules.luck, LootConfig.BOSS_CHEST_RARITY_WEIGHTS, random)
			local record = InventoryService.createItem(itemId, tier, rarity)
			local who = players[(i - 1) % #players + 1]
			if InventoryService.give(who, record) then
				notify(who, Items.displayName(record))
			else
				LootBagService.drop(chest.Position + Vector3.new(0, 2, 0), { record }, { who })
				notify(who, "BagFull")
			end
		end
		chest:Destroy()
	end)
	return chest
end

return table.freeze(SplitChest)
