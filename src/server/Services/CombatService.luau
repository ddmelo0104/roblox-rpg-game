--!strict
--[[
	CombatService.luau
	Abilities and basic attacks (US-012, US-021 to US-024, Combat and Abilities tab). The kit comes
	from the equipment: the weapon gives the basic attack and 3 abilities, and the chest gives one
	more ability. The client only asks ("this ability in this direction", "on this locked target",
	"on this point"); the server checks that the ability belongs to what the player wears, then the
	cooldown, target, range, line of sight and energy, works out who was hit with the math in
	Shared.Abilities and the lag margin (ADR-009), applies the damage and tells every client.
	Models with the target tag (dummies and enemies) take damage through DamageService. Other
	players are targets only where the zone rules allow PvP (US-036, ZoneService.canPvp); a hit on a
	player goes through DefenseService, so their dodge and parry work, and a stunned character (a
	parried attacker) cannot use abilities. Attacking ends a player's zone entry protection.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Abilities = require(ReplicatedStorage.Shared.Abilities)
local ArmorConfig = require(ReplicatedStorage.Shared.Config.Armor)
local CameraConfig = require(ReplicatedStorage.Shared.Config.Camera)
local CombatConfig = require(ReplicatedStorage.Shared.Config.Combat)
local Items = require(ReplicatedStorage.Shared.Items)
local Knockdown = require(ReplicatedStorage.Shared.Knockdown)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Status = require(ReplicatedStorage.Shared.Status)
local Targets = require(ReplicatedStorage.Shared.Targets)
local Validate = require(ReplicatedStorage.Shared.Validate)
local Weapons = require(ReplicatedStorage.Shared.Weapons)
local Network = require(script.Parent.Parent.Network)
local CombatStateService = require(script.Parent.CombatStateService)
local DamageService = require(script.Parent.DamageService)
local DefenseService = require(script.Parent.DefenseService)
local GroupService = require(script.Parent.GroupService)
local EnergyService = require(script.Parent.EnergyService)
local InventoryService = require(script.Parent.InventoryService)
local StatsService = require(script.Parent.StatsService)
local ZoneService = require(script.Parent.ZoneService)

type Ability = Abilities.Ability
type RejectReason = Abilities.RejectReason

-- Id of the basic attack in the AbilityUsed notice.
local BASIC_ATTACK_ID = "BasicAttack"

local CombatService = {}

-- Every kit is checked on start; a wrong field in a weapon's Config stops with a clear message.
local IDS: { string } = {}
for weaponId, kit in Weapons.all() do
	for _, ability in Abilities.validate(kit.ABILITIES, `Config/{weaponId}`) do
		table.insert(IDS, ability.id)
	end
end
for _, chestAbility in ArmorConfig.CHEST_ABILITIES do
	table.insert(IDS, chestAbility.id)
end

-- Server time at which each ability of each player is ready again, and the next basic attack.
local readyAt: { [Player]: { [string]: number } } = {}
local basicReadyAt: { [Player]: number } = {}

local requestEvent = Remotes.event("RequestAbility")
local usedEvent = Remotes.event("AbilityUsed")

local function validateRequest(id: any, direction: any, target: any, point: any): (boolean, string?)
	local ok, reason = Validate.oneOf(id, IDS)
	if not ok then
		return false, reason
	end
	ok, reason = Validate.vector(direction, 0.5, 2)
	if not ok then
		return false, reason
	end
	ok, reason = Validate.instanceOrNil(target)
	if not ok then
		return false, reason
	end
	return Validate.pointOrNil(point)
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

-- What `player` may hit: the tagged targets, plus the characters of the players the zone rules let
-- them fight (US-036).
local function candidatesFor(player: Player): { Model }
	local list = Targets.all()
	for _, other in Players:GetPlayers() do
		local character = other.Character
		if
			character
			and ZoneService.canPvp(player, other)
			and not GroupService.sameGroup(player, other)
			and not Knockdown.isDowned(other)
		then
			table.insert(list, character)
		end
	end
	return list
end

-- Whether `instance` is something `player` may hit.
local function isValidTarget(player: Player, instance: Instance): boolean
	if Targets.isTarget(instance) then
		return true
	end
	local victim = Players:GetPlayerFromCharacter(instance)
	return victim ~= nil
		and ZoneService.canPvp(player, victim)
		and not GroupService.sameGroup(player, victim)
		and not Knockdown.isDowned(victim)
end

-- The living targets inside the area (Front or Around) that the attacker can see.
local function targetsInArea(player: Player, ability: Ability, origin: Vector3, forward: Vector3): { Model }
	local ignore = nonBlocking()
	local hits: { Model } = {}
	for _, target in candidatesFor(player) do
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
local function checkTarget(
	player: Player,
	ability: Ability,
	origin: Vector3,
	requested: Instance?
): (Model?, RejectReason?)
	if not requested or not isValidTarget(player, requested) then
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

-- Takes health from the hit targets, in the player's name (DamageService writes down who dealt it).
-- A hit on another player goes through their defense (dodge and parry), as a `hitKind` hit. Returns
-- whether this hit knocked a target down (a player's defense answers later, so it never counts).
local function applyDamage(player: Player, hits: { Model }, damage: number, hitKind: any): boolean
	local knockedDown = false
	for _, target in hits do
		local victim = Players:GetPlayerFromCharacter(target)
		if victim then
			task.spawn(DefenseService.receiveHit, victim, damage, hitKind, player.Character)
		elseif DamageService.deal(target, damage, player) then
			knockedDown = true
		end
	end
	return knockedDown
end

-- The living targets within `radius` of `point` (a Ground ability).
local function targetsAroundPoint(player: Player, point: Vector3, radius: number): { Model }
	local hits: { Model } = {}
	for _, target in candidatesFor(player) do
		local position = Targets.position(target)
		if
			position
			and Targets.isAlive(target)
			and Abilities.isInRadius(point, position, radius, CombatConfig.LAG_MARGIN, CombatConfig.MAX_HIT_HEIGHT)
		then
			table.insert(hits, target)
		end
	end
	return hits
end

-- The kit of the weapon the player wears, or nil.
local function kitOf(player: Player): any
	local weapon = InventoryService.equipped(player).Weapon
	return Weapons.kit(if weapon then weapon.itemId else nil)
end

-- The chest ability (US-024): energy, healing or resistance for the player.
local function useChestAbility(player: Player, chestAbility: any, humanoid: Humanoid, root: BasePart, now: number)
	local readyTimes = readyTimesOf(player)
	if now < (readyTimes[chestAbility.id] or 0) then
		respond(player, chestAbility.id, "OnCooldown")
		return
	end
	if not EnergyService.spend(player, chestAbility.energyCost) then
		respond(player, chestAbility.id, "NoEnergy")
		return
	end
	if chestAbility.effect == "RestoreEnergy" then
		EnergyService.restore(player, chestAbility.amount)
	elseif chestAbility.effect == "Heal" then
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + humanoid.MaxHealth * chestAbility.amount)
	elseif chestAbility.effect == "Resistance" then
		StatsService.addResistance(player, chestAbility.amount, chestAbility.duration)
	end
	local stats = StatsService.of(player)
	readyTimes[chestAbility.id] = now + chestAbility.cooldown * stats.cooldownMultiplier
	respond(player, chestAbility.id, nil)
	usedEvent:FireAllClients(player, chestAbility.id, root.CFrame, {}, 0, nil)
end

local function useAbility(player: Player, id: string, direction: Vector3, requestedTarget: Instance?, point: Vector3?)
	local humanoid, root = partsOf(player)
	if not humanoid or not root or humanoid.Health <= 0 then
		respond(player, id, "NoCharacter")
		return
	end
	if Knockdown.isDowned(player) then
		respond(player, id, "Downed")
		return
	end
	if Status.isStunned(player.Character :: Model) then
		respond(player, id, "Stunned")
		return
	end
	local now = Workspace:GetServerTimeNow()

	-- The chest ability, if the request is for the chest the player wears.
	local chestAbility = Items.chestAbilityOf(InventoryService.equipped(player))
	if chestAbility and chestAbility.id == id then
		useChestAbility(player, chestAbility, humanoid, root, now)
		return
	end

	-- Otherwise it must be an ability of the weapon the player wears.
	local kit = kitOf(player)
	local ability: Ability? = if kit then Abilities.byId(kit.ABILITIES, id) else nil
	if not ability then
		respond(player, id, "NoWeapon")
		return
	end

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
		local target, reason = checkTarget(player, ability, origin, requestedTarget)
		if not target then
			respond(player, id, reason)
			return
		end
		lockedTarget = target
		forward = Abilities.flatDirection((Targets.position(target) or origin) - origin) or forward
	elseif ability.shape == "Ground" then
		-- The point must be within the ability's range (with the lag margin).
		if not point then
			respond(player, id, "InvalidTarget")
			return
		end
		local margin = CombatConfig.LAG_MARGIN
		if not Abilities.isInRadius(origin, point, ability.range, margin, CombatConfig.MAX_HIT_HEIGHT * 2) then
			respond(player, id, "OutOfRange")
			return
		end
	end

	if not EnergyService.spend(player, ability.energyCost) then
		respond(player, id, "NoEnergy")
		return
	end

	-- The equipment scales the damage and shortens the cooldown (US-018).
	local stats = StatsService.of(player)
	local damage = ability.damage * stats.damageMultiplier
	local hits = if lockedTarget
		then { lockedTarget }
		elseif ability.shape == "Ground" and point then targetsAroundPoint(player, point, ability.radius)
		else targetsInArea(player, ability, origin, forward)
	local knockedDown = applyDamage(player, hits, damage, kit.HIT_KIND)
	ZoneService.onAttack(player)
	if #hits > 0 then
		CombatStateService.mark(player)
	end

	readyTimes[id] = if knockedDown and ability.resetOnKill
		then now
		else now + ability.cooldown * stats.cooldownMultiplier
	respond(player, id, nil)
	usedEvent:FireAllClients(player, id, CFrame.lookAt(origin, origin + forward), hits, damage, point)
end

-- The basic attack (US-023): no energy; it hits the locked target if it is valid and in reach,
-- otherwise the nearest target in a cone in front of the player (aim assist).
local function basicAttack(player: Player, requestedTarget: Instance?)
	local humanoid, root = partsOf(player)
	local kit = kitOf(player)
	if not humanoid or not root or humanoid.Health <= 0 or not kit then
		return
	end
	if Knockdown.isDowned(player) or Status.isStunned(player.Character :: Model) then
		return
	end
	local now = Workspace:GetServerTimeNow()
	if now < (basicReadyAt[player] or 0) then
		return
	end
	local basic = kit.BASIC_ATTACK
	local origin = root.Position
	local eye = eyeOf(origin)
	local ignore = nonBlocking()
	local margin, maxHeight = CombatConfig.LAG_MARGIN, CombatConfig.MAX_HIT_HEIGHT

	local function reachable(target: Model): boolean
		local position = Targets.position(target)
		return position ~= nil
			and Targets.isAlive(target)
			and Abilities.isInRadius(origin, position, basic.range, margin, maxHeight)
			and Targets.hasLineOfSight(eye, position, ignore)
	end

	local target: Model? = nil
	if requestedTarget and isValidTarget(player, requestedTarget) and reachable(requestedTarget :: Model) then
		target = requestedTarget :: Model
	else
		local forward = Abilities.flatDirection(root.CFrame.LookVector) or Vector3.new(0, 0, -1)
		local bestDistance = math.huge
		for _, candidate in candidatesFor(player) do
			local position = Targets.position(candidate)
			if
				position
				and Abilities.isInCone(origin, forward, position, basic.range + margin, basic.coneAngle, maxHeight)
				and reachable(candidate)
			then
				local distance = (position - origin).Magnitude
				if distance < bestDistance then
					target = candidate
					bestDistance = distance
				end
			end
		end
	end
	if not target then
		return
	end

	basicReadyAt[player] = now + basic.interval
	local damage = basic.damage * StatsService.of(player).damageMultiplier
	applyDamage(player, { target }, damage, kit.HIT_KIND)
	CombatStateService.mark(player)
	ZoneService.onAttack(player)
	usedEvent:FireAllClients(player, BASIC_ATTACK_ID, root.CFrame, { target }, damage, nil)
end

function CombatService:Start()
	Network.onReceive("RequestAbility", validateRequest, useAbility)
	Network.onReceive("RequestBasicAttack", Validate.instanceOrNil, basicAttack)

	-- AbilityUsed is a server notice only. Listening and ignoring it avoids a queue of events with no
	-- handler if a client fires it.
	usedEvent.OnServerEvent:Connect(function() end)

	Players.PlayerRemoving:Connect(function(player)
		readyAt[player] = nil
		basicReadyAt[player] = nil
	end)
end

return CombatService
