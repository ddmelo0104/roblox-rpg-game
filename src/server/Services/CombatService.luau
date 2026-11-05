--!strict
--[[
	CombatService.luau
	Abilities of the prototype's longsword (US-012, Combat and Abilities tab). The client only asks
	("front slash in this direction", "target strike on this locked target"). The server checks the
	cooldown, target, range, line of sight and energy, works out who was hit with the math in
	Shared.Abilities and the lag margin (ADR-009), applies the damage and tells every client.
	Only models with the target tag take damage: PvP depends on the zone rules, which do not exist yet.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Abilities = require(ReplicatedStorage.Shared.Abilities)
local CameraConfig = require(ReplicatedStorage.Shared.Config.Camera)
local CombatConfig = require(ReplicatedStorage.Shared.Config.Combat)
local LongswordConfig = require(ReplicatedStorage.Shared.Config.Longsword)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Targets = require(ReplicatedStorage.Shared.Targets)
local Validate = require(ReplicatedStorage.Shared.Validate)
local Network = require(script.Parent.Parent.Network)
local EnergyService = require(script.Parent.EnergyService)

type Ability = Abilities.Ability
type RejectReason = Abilities.RejectReason

local CombatService = {}

-- The prototype's weapon; stops with a clear message if a field in the Config is wrong.
local ABILITIES = Abilities.validate(LongswordConfig, "Config/Longsword")

-- Ids the client may request.
local IDS: { string } = {}
for _, ability in ABILITIES do
	table.insert(IDS, ability.id)
end

-- Server time at which each ability of each player is ready again.
local readyAt: { [Player]: { [string]: number } } = {}

local requestEvent = Remotes.event("RequestAbility")
local usedEvent = Remotes.event("AbilityUsed")

local function validateRequest(id: any, direction: any, target: any): (boolean, string?)
	local ok, reason = Validate.oneOf(id, IDS)
	if not ok then
		return false, reason
	end
	ok, reason = Validate.vector(direction, 0.5, 2)
	if not ok then
		return false, reason
	end
	return Validate.instanceOrNil(target)
end

local function readyTimesOf(player: Player): { [string]: number }
	local existing = readyAt[player]
	if existing then
		return existing
	end
	local created: { [string]: number } = {}
	readyAt[player] = created
	return created
end

-- Answers only the player who asked: when the ability is ready and, if it was rejected, why.
local function respond(player: Player, id: string, reason: RejectReason?)
	requestEvent:FireClient(player, id, readyTimesOf(player)[id] or 0, reason)
end

local function partsOf(player: Player): (Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	return character:FindFirstChildOfClass("Humanoid"), if root and root:IsA("BasePart") then root else nil
end

-- Characters and targets block neither hits nor line of sight: only the scenery does.
local function nonBlocking(): { Instance }
	local list: { Instance } = {}
	for _, other in Players:GetPlayers() do
		local character = other.Character
		if character then
			table.insert(list, character)
		end
	end
	for _, target in Targets.all() do
		table.insert(list, target)
	end
	return list
end

local function eyeOf(origin: Vector3): Vector3
	return origin + Vector3.new(0, CameraConfig.FOCUS_HEIGHT, 0)
end

-- The living targets inside the area (Front or Around) that the attacker can see.
local function targetsInArea(ability: Ability, origin: Vector3, forward: Vector3): { Model }
	local ignore = nonBlocking()
	local hits: { Model } = {}
	for _, target in Targets.all() do
		local position = Targets.position(target)
		if not position or not Targets.isAlive(target) then
			continue
		end
		local margin, maxHeight = CombatConfig.LAG_MARGIN, CombatConfig.MAX_HIT_HEIGHT
		local inside = if ability.shape == "Front"
			then Abilities.isInFront(origin, forward, position, ability.range, ability.width, margin, maxHeight)
			else Abilities.isInRadius(origin, position, ability.range, margin, maxHeight)
		if inside and Targets.hasLineOfSight(eyeOf(origin), position, ignore) then
			table.insert(hits, target)
		end
	end
	return hits
end

-- Checks the locked target of the target strike. Returns the target, or nil and the reject reason.
local function checkTarget(ability: Ability, origin: Vector3, requested: Instance?): (Model?, RejectReason?)
	if not requested or not Targets.isTarget(requested) then
		return nil, "InvalidTarget"
	end
	local target = requested :: Model
	local position = Targets.position(target)
	if not position or not Targets.isAlive(target) then
		return nil, "InvalidTarget"
	end
	local margin, maxHeight = CombatConfig.LAG_MARGIN, CombatConfig.MAX_HIT_HEIGHT
	if not Abilities.isInRadius(origin, position, ability.range, margin, maxHeight) then
		return nil, "OutOfRange"
	end
	if not Targets.hasLineOfSight(eyeOf(origin), position, nonBlocking()) then
		return nil, "NoLineOfSight"
	end
	return target, nil
end

-- Takes health from the hit targets. Returns whether this hit knocked any of them down.
local function applyDamage(hits: { Model }, damage: number): boolean
	local knockedDown = false
	for _, target in hits do
		local humanoid = target:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid:TakeDamage(damage)
			if humanoid.Health <= 0 then
				knockedDown = true
			end
		end
	end
	return knockedDown
end

local function useAbility(player: Player, id: string, direction: Vector3, requestedTarget: Instance?)
	local ability = Abilities.byId(ABILITIES, id)
	local humanoid, root = partsOf(player)
	if not ability or not humanoid or not root or humanoid.Health <= 0 then
		respond(player, id, "NoCharacter")
		return
	end

	local now = Workspace:GetServerTimeNow()
	local readyTimes = readyTimesOf(player)
	if now < (readyTimes[id] or 0) then
		respond(player, id, "OnCooldown")
		return
	end

	local origin = root.Position
	local forward = Abilities.flatDirection(direction)
		or Abilities.flatDirection(root.CFrame.LookVector)
		or Vector3.new(0, 0, -1)

	local lockedTarget: Model? = nil
	if ability.shape == "Target" then
		local target, reason = checkTarget(ability, origin, requestedTarget)
		if not target then
			respond(player, id, reason)
			return
		end
		lockedTarget = target
		forward = Abilities.flatDirection((Targets.position(target) or origin) - origin) or forward
	end

	if not EnergyService.spend(player, ability.energyCost) then
		respond(player, id, "NoEnergy")
		return
	end

	local hits = if lockedTarget then { lockedTarget } else targetsInArea(ability, origin, forward)
	local knockedDown = applyDamage(hits, ability.damage)

	readyTimes[id] = if knockedDown and ability.resetOnKill then now else now + ability.cooldown
	respond(player, id, nil)
	usedEvent:FireAllClients(player, id, CFrame.lookAt(origin, origin + forward), hits, ability.damage)
end

function CombatService:Start()
	Network.onReceive("RequestAbility", validateRequest, useAbility)

	-- AbilityUsed is a server notice only. Listening and ignoring it avoids a queue of events with no
	-- handler if a client fires it.
	usedEvent.OnServerEvent:Connect(function() end)

	Players.PlayerRemoving:Connect(function(player)
		readyAt[player] = nil
	end)
end

return CombatService
