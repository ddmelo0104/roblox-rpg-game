--!strict
--[[
	ZoneService.luau
	The zones of the world (EP-007, Zones and Risk tab). Every part with the "Zone" tag, built in
	Studio, is a zone region (US-035); its attributes say the kind (Zone: Blue, City, Yellow, Red or
	Black), the tier (Tier) and the name players see (ZoneName). If the place has none, a test layout
	appears to the left of the spawn (Config/Zones.TEST_LAYOUT). The regions are read in Init, so
	EnemyService finds them when it places enemies.

	Every ZONE_CHECK_INTERVAL it finds the zone of each player and publishes it as attributes
	(Shared.Zones), which the HUD reads. Rules it applies (US-037):
	- A player in combat (Shared.CombatState) cannot change zones: they are put back where they were.
	- Entering a PvP zone gives ENTRY_PROTECTION seconds of protection from other players; attacking
	  ends it.
	CombatService asks `canPvp` before a player hits another (US-036), and DefenseService asks
	`isSafe` before a hit lands on a player (nobody takes damage in the city).

	Parts with the "ReturnPoint" tag mark where players come back (EP-009): a player who gives up
	comes back at the return point of their zone, and one who lost everything, at the nearest city.
	The test layout has one in each zone.

	Each player also gets the world's zones for the map (US-044, ZoneMap): the bounds of every
	region on the ground, dungeons left out, again whenever the regions change.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CombatState = require(ReplicatedStorage.Shared.CombatState)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Zones = require(ReplicatedStorage.Shared.Zones)
local ZonesConfig = require(ReplicatedStorage.Shared.Config.Zones)
local MovementValidationService = require(script.Parent.MovementValidationService)

type Zone = Zones.Zone

-- What the service knows about each player: their zone and the last place they stood in it.
type Tracked = { zone: Zone, lastCFrame: CFrame? }

-- Game text (Portuguese) of the notice when a player in combat tries to leave their zone.
local ZONE_NOTICE_NAME = "Zona"

local ZoneService = {}

local regions: { BasePart } = {}
local changedListeners: { (player: Player, zone: Zone) -> () } = {}
-- The regions changed since the map was last sent.
local mapDirty = false
local RETURN_TAG = Zones.RETURN_TAG
local tracked: { [Player]: Tracked } = {}

-- Two zones are the same zone if they come from the same region or share a ZoneId (US-056).
local function sameZone(a: Zone, b: Zone): boolean
	return Zones.same(a, b)
end

local function addRegion(instance: Instance)
	if instance:IsA("BasePart") and not table.find(regions, instance) then
		mapDirty = true
		-- A region only marks a place: it must not block players, sight or the ground checks.
		instance.Anchored = true
		instance.Transparency = 1
		instance.CanCollide = false
		instance.CanQuery = false
		instance.CanTouch = false
		table.insert(regions, instance)
	end
end

local function removeRegion(instance: Instance)
	local index = table.find(regions, instance :: any)
	if index then
		table.remove(regions, index)
		mapDirty = true
	end
end

-- The world's zones for the map: the bounds of each region on the ground (dungeons left out), and
-- whether it is round. Only the biggest region of each zone carries its name (`label`).
local function mapOfZones(): { any }
	local list = {}
	local biggest: { [string]: any } = {}
	for _, region in regions do
		if region:GetAttribute("Dungeon") ~= true then
			local zone = Zones.fromRegion(region)
			local radius = Zones.radiusOf(region)
			local minX, maxX, minZ, maxZ
			if radius then
				minX, maxX = region.Position.X - radius, region.Position.X + radius
				minZ, maxZ = region.Position.Z - radius, region.Position.Z + radius
			else
				local half = region.Size / 2
				minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
				for _, sx in { -1, 1 } do
					for _, sz in { -1, 1 } do
						local corner = region.CFrame * Vector3.new(sx * half.X, 0, sz * half.Z)
						minX, maxX = math.min(minX, corner.X), math.max(maxX, corner.X)
						minZ, maxZ = math.min(minZ, corner.Z), math.max(maxZ, corner.Z)
					end
				end
			end
			local entry = {
				kind = zone.kind,
				tier = zone.tier,
				name = zone.name,
				minX = minX,
				maxX = maxX,
				minZ = minZ,
				maxZ = maxZ,
				round = radius ~= nil,
				label = true,
			}
			table.insert(list, entry)
			if zone.id then
				local area = (maxX - minX) * (maxZ - minZ)
				local current = biggest[zone.id]
				if current then
					if area > (current.maxX - current.minX) * (current.maxZ - current.minZ) then
						current.label = false
						biggest[zone.id] = entry
					else
						entry.label = false
					end
				else
					biggest[zone.id] = entry
				end
			end
		end
	end
	return list
end

-- The test layout: the M1 line of zones (Blue, city, Yellow, Red) to the left of the spawn.
local function createTestLayout()
	local layout = ZonesConfig.TEST_LAYOUT
	local spawnLocation = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	local base = if spawnLocation and spawnLocation:IsA("BasePart") then spawnLocation.CFrame else CFrame.new()
	local folder = Instance.new("Folder")
	folder.Name = "ZoneTestLayout"
	folder.Parent = Workspace
	for _, spec in layout.zones do
		local width = spec.to - spec.from
		local part = Instance.new("Part")
		part.Name = spec.name
		part.Size = Vector3.new(width, layout.height, layout.depth)
		part.CFrame = base * CFrame.new(-(spec.from + width / 2), 0, 0)
		part:SetAttribute("Zone", spec.zone)
		part:SetAttribute("Tier", spec.tier)
		part:SetAttribute("ZoneName", spec.name)
		part.Parent = folder
		CollectionService:AddTag(part, Zones.TAG)

		local back = Instance.new("Part")
		back.Name = `{spec.name} (retorno)`
		back.Size = Vector3.new(4, 1, 4)
		back.CFrame = base * CFrame.new(-(spec.from + width / 2), 0, 0)
		back.Anchored = true
		back.CanCollide = false
		back.CanQuery = false
		back.CanTouch = false
		back.Transparency = 1
		back.Parent = folder
		CollectionService:AddTag(back, RETURN_TAG)
	end
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function publish(player: Player, zone: Zone)
	player:SetAttribute(Zones.KIND_ATTRIBUTE, zone.kind)
	player:SetAttribute(Zones.TIER_ATTRIBUTE, zone.tier)
	player:SetAttribute(Zones.NAME_ATTRIBUTE, zone.name)
	local region = zone.region
	player:SetAttribute(Zones.DUNGEON_ATTRIBUTE, region ~= nil and region:GetAttribute("Dungeon") == true)
end

local function enter(player: Player, state: Tracked, zone: Zone)
	state.zone = zone
	publish(player, zone)
	for _, listener in changedListeners do
		task.spawn(listener, player, zone)
	end
	if zone.rules.pvp then
		player:SetAttribute(Zones.PROTECTED_UNTIL, Workspace:GetServerTimeNow() + ZonesConfig.ENTRY_PROTECTION)
	else
		player:SetAttribute(Zones.PROTECTED_UNTIL, nil)
	end
end

local function check(player: Player)
	local root = rootOf(player)
	if not root then
		return
	end
	local zone = Zones.at(root.Position, regions)
	local state = tracked[player]
	if not state then
		-- A new character: whatever zone it appeared in.
		state = { zone = zone, lastCFrame = root.CFrame }
		tracked[player] = state
		enter(player, state, zone)
		return
	end
	if sameZone(state.zone, zone) then
		state.lastCFrame = root.CFrame
		return
	end
	if zone.region == nil and state.lastCFrame then
		-- Outside every zone is outside the map (US-056): back to the last place inside it.
		MovementValidationService.teleport(player, state.lastCFrame)
		Remotes.event("Notice"):FireClient(player, ZONE_NOTICE_NAME, "OutOfBounds")
		return
	end
	if CombatState.isInCombat(player) and state.lastCFrame then
		-- No running away across a border while in combat: back to the last place in the old zone.
		MovementValidationService.teleport(player, state.lastCFrame)
		Remotes.event("Notice"):FireClient(player, ZONE_NOTICE_NAME, "InCombatBorder")
		return
	end
	state.lastCFrame = root.CFrame
	enter(player, state, zone)
end

-- Where a player comes back (EP-009): the return point nearest to `near` among those in zones that
-- `accepts` (a function of the zone), or nil if there is none.
function ZoneService.returnPoint(near: Vector3, accepts: (zone: Zone) -> boolean): CFrame?
	local best: BasePart? = nil
	local bestDistance = math.huge
	for _, point in CollectionService:GetTagged(RETURN_TAG) do
		if point:IsA("BasePart") and accepts(Zones.at(point.Position, regions)) then
			local distance = (point.Position - near).Magnitude
			if distance < bestDistance then
				best = point
				bestDistance = distance
			end
		end
	end
	return if best then best.CFrame + Vector3.new(0, 4, 0) else nil
end

-- Runs `listener(player, zone)` whenever a player's zone changes (the tutorial, US-045).
function ZoneService.onZoneChanged(listener: (player: Player, zone: Zone) -> ())
	table.insert(changedListeners, listener)
end

-- The zone of a point (a spawn point, for example).
function ZoneService.zoneAt(point: Vector3): Zone
	return Zones.at(point, regions)
end

-- The zone the player is in now (the default zone before their first check).
function ZoneService.zoneOf(player: Player): Zone
	local state = tracked[player]
	return if state then state.zone else Zones.default()
end

-- Whether nobody can be hurt where the player is (the city).
function ZoneService.isSafe(player: Player): boolean
	return ZoneService.zoneOf(player).rules.safe == true
end

-- Whether `attacker` may hit `victim` (US-036): both in a PvP zone, and the victim no longer
-- protected after entering it.
function ZoneService.canPvp(attacker: Player, victim: Player): boolean
	if attacker == victim then
		return false
	end
	return ZoneService.zoneOf(attacker).rules.pvp == true
		and ZoneService.zoneOf(victim).rules.pvp == true
		and not Zones.isProtected(victim)
end

-- The server is moving the player somewhere else (a dungeon, a portal): their next zone is taken as
-- new, so the border rule does not pull them back.
function ZoneService.forget(player: Player)
	tracked[player] = nil
end

-- The player attacked (anything): the entry protection ends.
function ZoneService.onAttack(player: Player)
	if player:GetAttribute(Zones.PROTECTED_UNTIL) ~= nil then
		player:SetAttribute(Zones.PROTECTED_UNTIL, nil)
	end
end

function ZoneService:Init()
	CollectionService:GetInstanceAddedSignal(Zones.TAG):Connect(addRegion)
	CollectionService:GetInstanceRemovedSignal(Zones.TAG):Connect(removeRegion)
	for _, instance in CollectionService:GetTagged(Zones.TAG) do
		addRegion(instance)
	end
	if #regions == 0 then
		createTestLayout()
		for _, instance in CollectionService:GetTagged(Zones.TAG) do
			addRegion(instance) -- the added signal may be deferred: read the new regions now
		end
	end
end

function ZoneService:Start()
	Players.PlayerRemoving:Connect(function(player)
		tracked[player] = nil
	end)
	local function onCharacter(player: Player)
		tracked[player] = nil -- a new character starts with a fresh zone check
	end
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			onCharacter(player)
		end)
	end)
	for _, player in Players:GetPlayers() do
		player.CharacterAdded:Connect(function()
			onCharacter(player)
		end)
	end
	local mapEvent = Remotes.event("ZoneMap")
	mapEvent.OnServerEvent:Connect(function() end) -- a server notice only
	Players.PlayerAdded:Connect(function(player)
		mapEvent:FireClient(player, mapOfZones())
	end)
	for _, player in Players:GetPlayers() do
		mapEvent:FireClient(player, mapOfZones())
	end
	mapDirty = false
	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				check(player)
			end
			if mapDirty then
				mapDirty = false
				mapEvent:FireAllClients(mapOfZones())
			end
			task.wait(ZonesConfig.ZONE_CHECK_INTERVAL)
		end
	end)
end

return ZoneService
