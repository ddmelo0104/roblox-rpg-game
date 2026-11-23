--!strict
--[[
	DungeonService.luau
	The random solo dungeon (EP-010, Dungeons tab; ADR-007: instances in the zone's own server).
	- Entrances (US-042): parts with the "DungeonEntrance" tag are the possible entrance points. Up
	  to ACTIVE_ENTRANCES_PER_ZONE of each zone are open at a time, shown as a portal. Going in (out
	  of combat) creates the instance with a new seed, or joins the one already open there. The
	  entrance closes ENTRANCE_CLOSE_TIME after the last player went in, and another point of the
	  zone opens. The test layout gets one entrance point in each zone but the city.
	- Instances (US-041): Shared.DungeonLayout gives the rooms from the seed, and DungeonBuilder
	  builds them far from the world, with a zone region of the entrance's zone. An instance with
	  nobody inside and its entrance closed is removed (its enemies go with it).
	- Leaving (US-042): the portal that opens when the boss falls, or EXIT_CHANNEL_TIME seconds of
	  channeling out of combat (RequestDungeonExit); combat or a knockdown interrupts it.
	- Chests (US-043): the treasure room's, the mini-boss's and the boss's. The first player to
	  open one rolls its items, and they are split among everyone inside; what does not fit goes to
	  a loot bag for that player. A chest belongs to its instance, so leaving and coming back never
	  resets it.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CombatState = require(ReplicatedStorage.Shared.CombatState)
local DungeonLayout = require(ReplicatedStorage.Shared.DungeonLayout)
local DungeonsConfig = require(ReplicatedStorage.Shared.Config.Dungeons)
local InterfaceConfig = require(ReplicatedStorage.Shared.Config.Interface)
local Knockdown = require(ReplicatedStorage.Shared.Knockdown)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Validate = require(ReplicatedStorage.Shared.Validate)
local Zones = require(ReplicatedStorage.Shared.Zones)
local ZonesConfig = require(ReplicatedStorage.Shared.Config.Zones)
local DungeonBuilder = require(script.Parent.Parent.DungeonBuilder)
local SplitChest = require(script.Parent.Parent.SplitChest)
local Teleport = require(script.Parent.Parent.Teleport)
local Network = require(script.Parent.Parent.Network)
local EnemyService = require(script.Parent.EnemyService)
local ZoneService = require(script.Parent.ZoneService)

type DungeonInstance = {
	id: number,
	slot: number,
	seed: number,
	zone: Zones.Zone,
	built: DungeonBuilder.Built,
	-- Where players go when they leave.
	exitTo: CFrame,
	-- The entrance still open toward this instance, if any.
	entrance: Entrance?,
	emptySince: number?,
}

type Entrance = {
	part: BasePart,
	active: boolean,
	portal: BasePart?,
	instance: DungeonInstance?,
	closesAt: number?,
}

-- CollectionService tag of the entrance points, and the player attributes for the HUD.
local ENTRANCE_TAG = "DungeonEntrance"
local IN_DUNGEON_ATTRIBUTE = "InDungeon"
local EXIT_AT_ATTRIBUTE = "DungeonExitAt"

-- Game text (Portuguese) and the look of portals and chests.
local DUNGEON_NAME = "Dungeon"
local ENTER_TEXT = "Entrar na dungeon"
local LEAVE_TEXT = "Sair da dungeon"
local PORTAL_COLOR = Color3.fromRGB(150, 90, 255)
local ENTRANCE_REACH = 10

local DungeonService = {}

local random = Random.new()
local folder: Folder
local entrances: { Entrance } = {}
local instances: { DungeonInstance } = {}
local usedSlots: { [number]: boolean } = {}
local nextId = 0
-- The running exit channel of each player (a token, so a cancelled one stops).
local channels: { [Player]: {} } = {}

local function notify(player: Player, name: string, reason: string)
	Remotes.event("Notice"):FireClient(player, name, reason)
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return if root and root:IsA("BasePart") then root else nil
end

local function newPart(name: string, size: Vector3, cframe: CFrame, color: Color3, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Color = color
	part.Parent = parent
	return part
end

local function newPrompt(parent: Instance, actionText: string, objectText: string, reach: number): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.KeyboardKeyCode = InterfaceConfig.INTERACT_KEY
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = reach
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	return prompt
end

-- The players inside an instance: those whose zone is its region.
local function insideOf(instance: DungeonInstance): { Player }
	local list: { Player } = {}
	for _, player in Players:GetPlayers() do
		if ZoneService.zoneOf(player).region == instance.built.region then
			table.insert(list, player)
		end
	end
	return list
end

local function instanceOf(player: Player): DungeonInstance?
	local region = ZoneService.zoneOf(player).region
	for _, instance in instances do
		if instance.built.region == region then
			return instance
		end
	end
	return nil
end

-- Moves a player somewhere far (into or out of a dungeon).
local function moveTo(player: Player, cframe: CFrame)
	Teleport.move(player, cframe)
end

-- A chest of `count` items: the first player inside to open it rolls them, split among everyone
-- inside (US-043).
local function spawnChest(instance: DungeonInstance, cframe: CFrame, count: number)
	SplitChest.spawn({
		parent = instance.built.folder,
		cframe = cframe,
		count = count,
		zone = instance.zone,
		reach = DungeonsConfig.CHEST_REACH,
		canOpen = function(player)
			return instanceOf(player) == instance
		end,
		sharers = function()
			return insideOf(instance)
		end,
	})
end

local function openExitPortal(instance: DungeonInstance, cframe: CFrame)
	local portal =
		newPart("ExitPortal", Vector3.new(6, 9, 1), cframe * CFrame.new(0, 4.5, 0), PORTAL_COLOR, instance.built.folder)
	portal.Material = Enum.Material.Neon
	portal.Transparency = 0.3
	newPrompt(portal, LEAVE_TEXT, DUNGEON_NAME, ENTRANCE_REACH).Triggered:Connect(function(player)
		if instanceOf(player) == instance then
			moveTo(player, instance.exitTo)
		end
	end)
end

local function freeSlot(): number
	local slot = 1
	while usedSlots[slot] do
		slot += 1
	end
	usedSlots[slot] = true
	return slot
end

local function createInstance(entrance: Entrance): DungeonInstance
	nextId += 1
	local slot = freeSlot()
	local seed = random:NextInteger(1, 2 ^ 31 - 1)
	local zone = ZoneService.zoneAt(entrance.part.Position)
	local origin =
		CFrame.new(DungeonsConfig.INSTANCE_ORIGIN + Vector3.new(0, 0, (slot - 1) * DungeonsConfig.INSTANCE_SPACING))
	local built = DungeonBuilder.build(DungeonLayout.generate(seed), origin, zone, `Dungeon{nextId}`)
	local instance: DungeonInstance = {
		id = nextId,
		slot = slot,
		seed = seed,
		zone = zone,
		built = built,
		exitTo = entrance.part.CFrame * CFrame.new(0, 4, 8),
		entrance = entrance,
		emptySince = nil,
	}
	for _, room in built.rooms do
		if room.kind == "Treasure" then
			spawnChest(instance, room.center * CFrame.new(0, 1.5, 0), DungeonsConfig.TREASURE_CHEST_ITEMS)
		end
	end
	built.folder.Parent = folder
	table.insert(instances, instance)
	print(`[Dungeon] instance {nextId} (seed {seed}) in {zone.name} T{zone.tier}`)
	return instance
end

local function destroyInstance(instance: DungeonInstance)
	local index = table.find(instances, instance)
	if index then
		table.remove(instances, index)
	end
	usedSlots[instance.slot] = nil
	instance.built.folder:Destroy()
end

local function closeEntrance(entrance: Entrance)
	entrance.active = false
	entrance.closesAt = nil
	if entrance.instance then
		entrance.instance.entrance = nil
		entrance.instance = nil
	end
	if entrance.portal then
		entrance.portal:Destroy()
		entrance.portal = nil
	end
end

local function enter(player: Player, entrance: Entrance)
	if not entrance.active then
		return
	end
	local root = rootOf(player)
	if not root or (root.Position - entrance.part.Position).Magnitude > ENTRANCE_REACH + 4 then
		notify(player, DUNGEON_NAME, "TooFar")
		return
	end
	if CombatState.isInCombat(player) or Knockdown.isDowned(player) then
		notify(player, DUNGEON_NAME, "InCombat")
		return
	end
	local instance = entrance.instance or createInstance(entrance)
	entrance.instance = instance
	local zone = ZoneService.zoneAt(entrance.part.Position)
	entrance.closesAt = os.clock() + ((DungeonsConfig.ENTRANCE_CLOSE_TIME :: any)[zone.kind] or 60)
	moveTo(player, instance.built.start)
end

local function openEntrance(entrance: Entrance)
	entrance.active = true
	local portal = newPart(
		"DungeonPortal",
		Vector3.new(6, 9, 1),
		entrance.part.CFrame * CFrame.new(0, 4.5, 0),
		PORTAL_COLOR,
		folder
	)
	portal.Material = Enum.Material.Neon
	portal.Transparency = 0.3
	entrance.portal = portal
	newPrompt(portal, ENTER_TEXT, DUNGEON_NAME, ENTRANCE_REACH).Triggered:Connect(function(player)
		enter(player, entrance)
	end)
end

-- Keeps ACTIVE_ENTRANCES_PER_ZONE open entrances in every zone, picking closed ones at random.
local function refreshEntrances()
	local byZone: { [any]: { Entrance } } = {}
	for _, entrance in entrances do
		if entrance.part.Parent then
			local key = ZoneService.zoneAt(entrance.part.Position).region or "default"
			byZone[key] = byZone[key] or {}
			table.insert(byZone[key], entrance)
		end
	end
	for _, group in byZone do
		local open = 0
		local closed: { Entrance } = {}
		for _, entrance in group do
			if entrance.active then
				open += 1
			else
				table.insert(closed, entrance)
			end
		end
		while open < DungeonsConfig.ACTIVE_ENTRANCES_PER_ZONE and #closed > 0 do
			local pick = table.remove(closed, random:NextInteger(1, #closed)) :: Entrance
			openEntrance(pick)
			open += 1
		end
	end
end

local function addEntrance(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	for _, entrance in entrances do
		if entrance.part == part then
			return -- already known
		end
	end
	part.Anchored = true
	part.Transparency = 1
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	table.insert(entrances, { part = part, active = false, portal = nil, instance = nil, closesAt = nil })
end

-- The test entrances: one in the middle of each test zone but the city, beside the enemy row.
local function createTestEntrances()
	local spawnLocation = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	local base = if spawnLocation and spawnLocation:IsA("BasePart") then spawnLocation.CFrame else CFrame.new()
	local testFolder = Instance.new("Folder")
	testFolder.Name = "DungeonTestEntrances"
	for _, spec in ZonesConfig.TEST_LAYOUT.zones do
		if spec.zone ~= "City" then
			local point = Instance.new("Part")
			point.Name = `Entrada ({spec.name})`
			point.Size = Vector3.new(2, 1, 2)
			point.CFrame = base * CFrame.new(-(spec.from + spec.to) / 2, 0, 80)
			point.Parent = testFolder
			CollectionService:AddTag(point, ENTRANCE_TAG)
		end
	end
	testFolder.Parent = Workspace
end

local function cancelExit(player: Player, reason: string?)
	if channels[player] then
		channels[player] = nil
		player:SetAttribute(EXIT_AT_ATTRIBUTE, nil)
		if reason then
			notify(player, DUNGEON_NAME, reason)
		end
	end
end

-- Leaving before the end: channel EXIT_CHANNEL_TIME seconds out of combat (US-042).
local function requestExit(player: Player, wants: boolean)
	if not wants then
		cancelExit(player, nil)
		return
	end
	local instance = instanceOf(player)
	if not instance or channels[player] then
		return
	end
	if CombatState.isInCombat(player) or Knockdown.isDowned(player) then
		notify(player, DUNGEON_NAME, "InCombat")
		return
	end
	local token = {}
	channels[player] = token
	local endsAt = Workspace:GetServerTimeNow() + DungeonsConfig.EXIT_CHANNEL_TIME
	player:SetAttribute(EXIT_AT_ATTRIBUTE, endsAt)
	task.spawn(function()
		while channels[player] == token do
			if CombatState.isInCombat(player) or Knockdown.isDowned(player) or instanceOf(player) ~= instance then
				cancelExit(player, "Interrupted")
				return
			end
			if Workspace:GetServerTimeNow() >= endsAt then
				cancelExit(player, nil)
				moveTo(player, instance.exitTo)
				return
			end
			task.wait(0.25)
		end
	end)
end

-- A boss or a mini-boss fell: its chest, and the exit portal after the boss (US-043).
local function onKill(kill: EnemyService.Kill)
	local role = kill.point:GetAttribute("DungeonRole")
	if role ~= "MiniBoss" and role ~= "Boss" then
		return
	end
	for _, instance in instances do
		if kill.point:IsDescendantOf(instance.built.folder) then
			local count = if role == "Boss"
				then DungeonsConfig.BOSS_CHEST_ITEMS
				else DungeonsConfig.MINIBOSS_CHEST_ITEMS
			spawnChest(instance, CFrame.new(kill.position + Vector3.new(0, 1.5, 0)), count)
			if role == "Boss" then
				openExitPortal(instance, CFrame.new(kill.position + Vector3.new(0, 0, -8)))
			end
			return
		end
	end
end

local function tick()
	local now = os.clock()
	for _, entrance in entrances do
		if entrance.active and entrance.closesAt and now >= entrance.closesAt then
			closeEntrance(entrance)
		end
	end
	refreshEntrances()

	local insideAny: { [Player]: boolean } = {}
	for _, instance in table.clone(instances) do
		local inside = insideOf(instance)
		for _, player in inside do
			insideAny[player] = true
		end
		if #inside > 0 or instance.entrance then
			instance.emptySince = nil
		elseif not instance.emptySince then
			instance.emptySince = now
		elseif now - instance.emptySince >= DungeonsConfig.EMPTY_INSTANCE_LIFETIME then
			destroyInstance(instance)
		end
	end
	for _, player in Players:GetPlayers() do
		local inside = insideAny[player] == true
		if player:GetAttribute(IN_DUNGEON_ATTRIBUTE) ~= inside then
			player:SetAttribute(IN_DUNGEON_ATTRIBUTE, inside)
		end
	end
end

function DungeonService:Init()
	folder = Instance.new("Folder")
	folder.Name = "Dungeons"
	folder.Parent = Workspace
end

function DungeonService:Start()
	Network.onReceive("RequestDungeonExit", Validate.boolean, requestExit)
	EnemyService.onKilled(onKill)

	CollectionService:GetInstanceAddedSignal(ENTRANCE_TAG):Connect(addEntrance)
	for _, part in CollectionService:GetTagged(ENTRANCE_TAG) do
		addEntrance(part)
	end
	if #entrances == 0 and Workspace:FindFirstChild("ZoneTestLayout") then
		createTestEntrances()
		for _, part in CollectionService:GetTagged(ENTRANCE_TAG) do
			addEntrance(part) -- the added signal may be deferred: read the new points now
		end
	end
	refreshEntrances()

	Players.PlayerRemoving:Connect(function(player)
		channels[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			tick()
		end
	end)
end

return DungeonService
