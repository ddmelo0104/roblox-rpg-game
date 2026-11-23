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
local tracked: { [Player]: Tracked } = {}

-- Two zones are the same zone if they come from the same region (or are both the default).
local function sameZone(a: Zone, b: Zone): boolean
	return a.region == b.region
end

local function addRegion(instance: Instance)
	if instance:IsA("BasePart") and not table.find(regions, instance) then
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
	end
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
end

local function enter(player: Player, state: Tracked, zone: Zone)
	state.zone = zone
	publish(player, zone)
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
	if CombatState.isInCombat(player) and state.lastCFrame then
		-- No running away across a border while in combat: back to the last place in the old zone.
		MovementValidationService.teleport(player, state.lastCFrame)
		Remotes.event("Notice"):FireClient(player, ZONE_NOTICE_NAME, "InCombatBorder")
		return
	end
	state.lastCFrame = root.CFrame
	enter(player, state, zone)
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
	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				check(player)
			end
			task.wait(ZonesConfig.ZONE_CHECK_INTERVAL)
		end
	end)
end

return ZoneService
