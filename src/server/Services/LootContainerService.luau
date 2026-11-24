--!strict
--[[
	LootContainerService.luau
	Containers whose items players take one by one (US-051; Davi, 2026-11-23: "items collected from
	the chests instead of received at once"): chests and loot bags. Opening one shows the player a
	loot window with what it holds for them (ContainerView). They take an item (RequestTakeItem) or
	everything that fits (RequestTakeAll), and the server checks the distance and the access every
	time. Each item leaves the container in the same step it enters the bag, with no yields, so an
	item is never in two places (rule 6); what does not fit stays.
	A container's items can be shared (a loot bag) or one share per player (a split chest): the
	container says which list each player sees.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Validate = require(ReplicatedStorage.Shared.Validate)
local Network = require(script.Parent.Parent.Network)
local InventoryService = require(script.Parent.InventoryService)

type ItemRecord = Items.ItemRecord

export type Spec = {
	title: string,
	part: BasePart,
	reach: number,
	-- The list of items this player sees (the container changes it as items are taken), or nil.
	itemsFor: (player: Player) -> { ItemRecord }?,
	-- Whether this player may open it now, and the reason shown when not.
	canOpen: (player: Player) -> (boolean, string?),
	-- Whether nothing is left for anyone.
	isEmpty: () -> boolean,
	-- Runs when the last item was taken (usually removes the part).
	onEmptied: (() -> ())?,
}

export type Container = Spec & { id: string, viewers: { [Player]: boolean } }

-- A uid or a container id is a GUID: 36 characters.
local MAX_ID_LENGTH = 64

-- Game text (Portuguese): the notice after taking several items ("3 itens pegos").
local TAKEN_TEXT = "itens pegos"

local LootContainerService = {}

local containers: { [string]: Container } = {}
local viewEvent = Remotes.event("ContainerView")

local function notify(player: Player, title: string, reason: string)
	Remotes.event("Notice"):FireClient(player, title, reason)
end

local function isNear(player: Player, container: Container): boolean
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return root ~= nil
		and root:IsA("BasePart")
		and (root.Position - container.part.Position).Magnitude <= container.reach + 4
end

local function copies(items: { ItemRecord }): { ItemRecord }
	local list: { ItemRecord } = {}
	for _, record in items do
		table.insert(list, table.clone(record))
	end
	return list
end

local function show(player: Player, container: Container)
	viewEvent:FireClient(player, {
		id = container.id,
		title = container.title,
		position = container.part.Position,
		reach = container.reach,
		items = copies(container.itemsFor(player) or {}),
	})
end

-- Registers a container. Its part's prompt calls `open`.
function LootContainerService.create(spec: Spec): Container
	local container = spec :: Container
	container.id = HttpService:GenerateGUID(false)
	container.viewers = {}
	containers[container.id] = container
	-- A container goes away with its part (a dungeon removed, a bag that expired).
	spec.part.Destroying:Connect(function()
		LootContainerService.remove(container)
	end)
	return container
end

-- Shows the container to the player, if they are near and allowed.
function LootContainerService.open(player: Player, container: Container)
	if not containers[container.id] then
		return
	end
	if not isNear(player, container) then
		notify(player, container.title, "TooFar")
		return
	end
	local allowed, reason = container.canOpen(player)
	if not allowed then
		notify(player, container.title, reason or "NotYours")
		return
	end
	container.viewers[player] = true
	show(player, container)
end

-- Sends the current items to everyone looking at the container.
function LootContainerService.refresh(container: Container)
	for player in container.viewers do
		if player.Parent then
			show(player, container)
		else
			container.viewers[player] = nil
		end
	end
end

-- Forgets the container and closes every window on it.
function LootContainerService.remove(container: Container)
	if not containers[container.id] then
		return
	end
	containers[container.id] = nil
	for player in container.viewers do
		if player.Parent then
			viewEvent:FireClient(player, { id = container.id, closed = true })
		end
	end
	container.viewers = {}
end

-- Moves the item `uid` (or, with nil, everything that fits) from the container to the bag.
local function take(player: Player, id: string, uid: string?)
	local container = containers[id]
	if not container then
		return
	end
	if not isNear(player, container) then
		notify(player, container.title, "TooFar")
		return
	end
	local allowed, reason = container.canOpen(player)
	local items = if allowed then container.itemsFor(player) else nil
	if not items then
		notify(player, container.title, reason or "NotYours")
		return
	end
	-- No yields from here on: each item leaves the container in the step it enters the bag.
	local index = 1
	local full = false
	local taken: { ItemRecord } = {}
	while index <= #items do
		local record = items[index]
		if uid == nil or record.uid == uid then
			-- Out of the container first, then into the bag: even if something on the way yielded,
			-- the item would never be in both. A full bag puts it back where it was.
			table.remove(items, index)
			if not InventoryService.give(player, record) then
				table.insert(items, index, record)
				full = true
				break
			end
			table.insert(taken, record)
			if uid then
				break
			end
		else
			index += 1
		end
	end
	if full then
		notify(player, container.title, "BagFull")
	elseif #taken == 1 then
		notify(player, container.title, Items.displayName(taken[1]))
	elseif #taken > 1 then
		notify(player, container.title, `{#taken} {TAKEN_TEXT}`)
	end
	if container.isEmpty() then
		if container.onEmptied then
			container.onEmptied()
		end
		LootContainerService.remove(container)
	else
		LootContainerService.refresh(container)
	end
end

function LootContainerService:Start()
	local function validId(value: any)
		return Validate.shortString(value, MAX_ID_LENGTH)
	end
	Network.onReceive("RequestTakeItem", function(id, uid)
		local ok, reason = validId(id)
		if not ok then
			return ok, reason
		end
		return validId(uid)
	end, function(player, id, uid)
		take(player, id, uid)
	end)
	Network.onReceive("RequestTakeAll", validId, function(player, id)
		take(player, id, nil)
	end)
	Network.onReceive("RequestCloseContainer", validId, function(player, id)
		local container = containers[id]
		if container then
			container.viewers[player] = nil
		end
	end)
	viewEvent.OnServerEvent:Connect(function() end) -- a server notice only
	Players.PlayerRemoving:Connect(function(player)
		for _, container in containers do
			container.viewers[player] = nil
		end
	end)
end

return LootContainerService
