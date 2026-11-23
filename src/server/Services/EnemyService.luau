--!strict
--[[
	EnemyService.luau
	The enemies of the world (EP-008). Every part with the "EnemySpawn" tag, built in Studio, is a
	spawn point (US-027); its attributes say what appears there:
	- Enemy (string): the kind, a key of Config/Enemies.KINDS
	- Count (number, default 1) and Elite (boolean, default false)
	- Tier (number) and Zone (string: the zone kind, Config/Zones), for the strength, the loot's luck
	  and the fame. Without them, the spawn point takes the tier and kind of the zone region it
	  stands in (ZoneService, US-035).
	- RespawnTime (number, default Config/Enemies.RESPAWN_TIME) and Radius (number, default 5)
	- Respawns (boolean, default true): false for dungeon enemies, which never come back (US-043)
	When a spawn point is removed (a dungeon instance going away), its enemies go with it.
	If the place has no spawn point, test groups appear to the left of the spawn, one row through the
	test zones (Config/Enemies.TEST_AREA).

	One loop runs the AI of every enemy (EnemyBrain), with sleeping enemies checked only once in a
	while, and publishes once a second how many are awake and how much server time the AI took, for
	the performance overlay (US-025). When a player's hit knocks an enemy down (DamageService), the
	kill goes to the players who dealt at least Config/Loot.KILL_CREDIT_MIN_SHARE of the damage: the
	item chance is rolled and the item is left in a loot bag for them (US-026), and each of them gets
	the kill's fame times their share of the damage (US-029). The enemy comes back at its spawn point
	after RespawnTime.
]]

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local DebugConfig = require(ReplicatedStorage.Shared.Config.Debug)
local Enemies = require(ReplicatedStorage.Shared.Enemies)
local EnemiesConfig = require(ReplicatedStorage.Shared.Config.Enemies)
local Knockdown = require(ReplicatedStorage.Shared.Knockdown)
local Loot = require(ReplicatedStorage.Shared.Loot)
local GroupsConfig = require(ReplicatedStorage.Shared.Config.Groups)
local LootConfig = require(ReplicatedStorage.Shared.Config.Loot)
local ProgressionConfig = require(ReplicatedStorage.Shared.Config.Progression)
local Mastery = require(ReplicatedStorage.Shared.Mastery)
local Zones = require(ReplicatedStorage.Shared.Zones)
local ZonesConfig = require(ReplicatedStorage.Shared.Config.Zones)
local Targets = require(ReplicatedStorage.Shared.Targets)
local EnemyBody = require(script.Parent.Parent.EnemyBody)
local EnemyBrain = require(script.Parent.Parent.EnemyBrain)
local DamageService = require(script.Parent.DamageService)
local GroupService = require(script.Parent.GroupService)
local InventoryService = require(script.Parent.InventoryService)
local LootBagService = require(script.Parent.LootBagService)
local MasteryService = require(script.Parent.MasteryService)
local ZoneService = require(script.Parent.ZoneService)

type Enemy = EnemyBrain.Enemy

type SpawnPoint = {
	part: BasePart,
	kindId: string,
	kind: Enemies.Kind,
	elite: boolean,
	tier: number,
	luck: number,
	fameMultiplier: number,
	respawnTime: number,
	radius: number,
	respawns: boolean,
}

-- A kill, for the listeners (DungeonService opens the chests of its bosses): the spawn point, the
-- kind, where it fell and who earned it.
export type Kill = { point: BasePart, kindId: string, position: Vector3, credited: { Player } }

-- The stress test's enemies (Config/Debug.EXTRA_TEST_ENEMIES): how far ahead of the spawn, and the
-- space between them (studs).
local STRESS_DISTANCE = 400
local STRESS_SPACING = 12

local EnemyService = {}

local random = Random.new()
local folder: Folder
local enemies: { Enemy } = {}
local byModel: { [Model]: Enemy } = {}
local pointOf: { [Enemy]: SpawnPoint } = {}
local killListeners: { (kill: Kill) -> () } = {}

-- AI cost, for the overlay: seconds spent thinking since `windowStart`.
local aiTime = 0
local windowStart = os.clock()

local function groundBelow(point: Vector3, ignore: { Instance }): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local result = Workspace:Raycast(point + Vector3.new(0, 50, 0), Vector3.new(0, -200, 0), params)
	return if result then result.Position else point
end

local function attribute<T>(part: Instance, name: string, default: T): T
	local value = part:GetAttribute(name)
	return if typeof(value) == typeof(default) then value :: any else default
end

local function readPoint(part: Instance): SpawnPoint?
	if not part:IsA("BasePart") then
		return nil
	end
	local kindId = attribute(part, "Enemy", "")
	local kind = Enemies.kind(kindId)
	if not kind then
		warn(`[EnemyService] spawn point {part:GetFullName()} has no valid Enemy attribute: "{kindId}"`)
		return nil
	end
	-- Without its own Tier and Zone, a spawn point takes those of the zone region it stands in.
	local here = ZoneService.zoneAt(part.Position)
	local zoneKind = attribute(part, "Zone", here.kind)
	if not ZonesConfig.KINDS[zoneKind] then
		warn(`[EnemyService] spawn point {part:GetFullName()} has an unknown Zone: "{zoneKind}"`)
	end
	local rules = Zones.rules(zoneKind)
	-- A spawn point only marks a place: it must not block players, sight or the ground check.
	part.Anchored = true
	part.Transparency = 1
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	return {
		part = part,
		kindId = kindId,
		kind = kind,
		elite = attribute(part, "Elite", false),
		tier = attribute(part, "Tier", here.tier),
		luck = rules.luck,
		fameMultiplier = rules.fame,
		respawnTime = attribute(part, "RespawnTime", EnemiesConfig.RESPAWN_TIME),
		radius = attribute(part, "Radius", 5),
		respawns = attribute(part, "Respawns", true),
	}
end

local function removeFromList(enemy: Enemy)
	local index = table.find(enemies, enemy)
	if index then
		enemies[index] = enemies[#enemies]
		enemies[#enemies] = nil
	end
	byModel[enemy.model] = nil
	pointOf[enemy] = nil
end

local spawnOne: (point: SpawnPoint) -> ()

-- The players who earned a kill and the members of their groups near it (US-046).
local function earners(contributions: DamageService.Contributions, position: Vector3): { Player }
	local list: { Player } = {}
	for _, player in Enemies.credited(contributions, LootConfig.KILL_CREDIT_MIN_SHARE) do
		for _, member in GroupService.membersNear(player, position, GroupsConfig.SHARE_RANGE) do
			if not table.find(list, member) then
				table.insert(list, member)
			end
		end
	end
	return list
end

-- Rolls the item chance of a kill and leaves the item in a bag for the players who earned it and
-- their groups.
local function dropLoot(point: SpawnPoint, ground: Vector3, contributions: DamageService.Contributions)
	local owners = earners(contributions, ground)
	if #owners == 0 then
		return
	end
	local chance = if DebugConfig.DROP_EVERY_KILL then 1 else Enemies.itemChance(point.elite)
	if random:NextNumber() >= chance then
		return
	end
	local itemId, tier, rarity = Loot.roll(point.tier, point.luck, LootConfig.ENEMY_RARITY_WEIGHTS, random)
	local record = InventoryService.createItem(itemId, tier, rarity)
	LootBagService.drop(ground + Vector3.new(0, 0.8, 0), { record }, owners)
end

-- Gives the kill's fame to the players who earned it, each with their share of the damage. A group
-- (US-046) takes the share of all its members near the kill and splits it among them with the
-- group bonus: F × (1 + GROUP_FAME_BONUS × (n − 1)) / n each.
local function awardFame(point: SpawnPoint, contributions: DamageService.Contributions, position: Vector3)
	local total = 0
	for _, amount in contributions do
		total += amount
	end
	if total <= 0 then
		return
	end
	local fame = Mastery.killFame(point.tier, point.elite, point.fameMultiplier)
		* Enemies.rankFameMultiplier(point.kind)
	local done: { [Player]: boolean } = {}
	for _, player in Enemies.credited(contributions, LootConfig.KILL_CREDIT_MIN_SHARE) do
		if not done[player] then
			local members = GroupService.membersNear(player, position, GroupsConfig.SHARE_RANGE)
			local share = 0
			for _, member in members do
				share += contributions[member] or 0
				done[member] = true
			end
			local n = #members
			local each = fame * (share / total) * (1 + ProgressionConfig.GROUP_FAME_BONUS * (n - 1)) / n
			for _, member in members do
				if member.Parent then
					MasteryService.award(member, each)
				end
			end
		end
	end
end

-- The end of an enemy: `contributions` comes with a kill by players, and nil for any other death.
local function finish(enemy: Enemy, contributions: DamageService.Contributions?)
	if enemy.state == "Dead" then
		return
	end
	local point = pointOf[enemy]
	local root = enemy.root
	local ground = root.Position - Vector3.new(0, enemy.humanoid.HipHeight + root.Size.Y / 2, 0)
	EnemyBrain.die(enemy)
	removeFromList(enemy)
	EnemyBody.fallApart(enemy.model)
	Debris:AddItem(enemy.model, EnemiesConfig.CORPSE_TIME)
	if enemy.kind.deathBlast then
		task.spawn(EnemyBrain.blast, enemy, ground)
	end
	if point then
		if contributions then
			awardFame(point, contributions, ground)
			dropLoot(point, ground, contributions)
			local kill: Kill = {
				point = point.part,
				kindId = point.kindId,
				position = ground,
				credited = earners(contributions, ground),
			}
			for _, listener in killListeners do
				task.spawn(listener, kill)
			end
		end
		if point.respawns then
			task.delay(point.respawnTime, spawnOne, point)
		end
	end
end

spawnOne = function(point: SpawnPoint)
	if not point.part.Parent then
		return -- the spawn point was removed
	end
	local angle = random:NextNumber(0, 2 * math.pi)
	local distance = random:NextNumber(0, point.radius)
	local around = point.part.Position + Vector3.new(math.cos(angle), 0, math.sin(angle)) * distance
	local ground = groundBelow(around, { folder, point.part })
	local facing = Vector3.new(point.part.CFrame.LookVector.X, 0, point.part.CFrame.LookVector.Z)
	if facing.Magnitude < 0.01 then
		facing = Vector3.new(0, 0, -1)
	end

	local kind = point.kind
	local health, damage = Enemies.stats(kind, point.tier, point.elite)
	local scale = (kind.scale or 1) * (if point.elite then EnemiesConfig.ELITE.scale else 1)
	local model, humanoid, root, torso = EnemyBody.build(
		ground,
		facing.Unit,
		scale,
		kind.color,
		Enemies.displayName(kind, point.elite),
		health,
		kind.speed
	)
	model.Name = point.kindId
	CollectionService:AddTag(model, Targets.TAG)
	model.Parent = folder
	EnemyBody.claim(root)

	local enemy: Enemy = {
		model = model,
		humanoid = humanoid,
		root = root,
		torso = torso,
		kind = kind,
		damage = damage,
		damageScale = damage / kind.damage,
		home = root.CFrame,
		state = "Idle",
		target = nil,
		asleep = false,
		-- Spread the first decisions, so enemies that appear together do not all think in one frame.
		nextThinkAt = os.clock() + random:NextNumber(0, EnemiesConfig.THINK_INTERVAL),
		nextAttackAt = 0,
		lastPosition = root.Position,
		progressAt = 0,
		returnStartedAt = 0,
	}
	table.insert(enemies, enemy)
	byModel[model] = enemy
	pointOf[enemy] = point

	-- Any death that was not a kill by players (falling off the world, for example): no loot. The
	-- wait lets a kill by DamageService, which carries who earned it, arrive first.
	humanoid.Died:Connect(function()
		task.delay(0.5, finish, enemy, nil)
	end)
end

local function addPoint(part: Instance)
	local point = readPoint(part)
	if point then
		for _ = 1, math.max(1, math.floor(attribute(part, "Count", 1))) do
			spawnOne(point)
		end
	end
end

-- A spawn point made by code. It has no Tier or Zone: it takes those of the zone it stands in.
local function newPointPart(parent: Instance, cframe: CFrame, kindId: string): Part
	local part = Instance.new("Part")
	part.Name = "EnemySpawn"
	part.Size = Vector3.new(1, 1, 1)
	part.CFrame = cframe
	part:SetAttribute("Enemy", kindId)
	part.Parent = parent
	return part
end

local function spawnFrame(): CFrame
	local spawnLocation = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	return if spawnLocation and spawnLocation:IsA("BasePart") then spawnLocation.CFrame else CFrame.new()
end

-- The test groups (US-027): a row to the left of the spawn, through the test zones (US-035), away
-- from the dummies and the test chest.
local function createTestArea()
	local area = EnemiesConfig.TEST_AREA
	local areaFolder = Instance.new("Folder")
	areaFolder.Name = "EnemyTestArea"
	areaFolder.Parent = Workspace
	for _, group in area.groups do
		local cframe = spawnFrame() * CFrame.new(-group.left, 0, -area.ahead)
		local part = newPointPart(areaFolder, cframe, group.kind)
		part:SetAttribute("Count", group.count)
		part:SetAttribute("Elite", group.elite)
		part:SetAttribute("Radius", area.radius)
		CollectionService:AddTag(part, Enemies.SPAWN_TAG)
	end
end

-- The stress test (US-025): sleeping enemies in a grid far ahead of the spawn.
local function createStressTest(count: number)
	local stressFolder = Instance.new("Folder")
	stressFolder.Name = "EnemyStressTest"
	stressFolder.Parent = Workspace
	local columns = math.ceil(math.sqrt(count))
	local base = spawnFrame() * CFrame.new(-columns * STRESS_SPACING / 2, 0, -STRESS_DISTANCE)
	for i = 0, count - 1 do
		local offset = CFrame.new((i % columns) * STRESS_SPACING, 0, -math.floor(i / columns) * STRESS_SPACING)
		local part = newPointPart(stressFolder, base * offset, "BanditThug")
		part:SetAttribute("Radius", 0)
		CollectionService:AddTag(part, Enemies.SPAWN_TAG)
	end
end

local function livingPlayers(): { EnemyBrain.Living }
	local list: { EnemyBrain.Living } = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		-- A downed player is left alone (Zones and Risk tab: monsters stop attacking).
		if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") and not Knockdown.isDowned(player) then
			table.insert(list, { player = player, root = root })
		end
	end
	return list
end

-- What does not block an enemy's sight: the enemies, the characters and the training targets.
local function nonBlocking(): { Instance }
	local list: { Instance } = { folder }
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(list, player.Character)
		end
	end
	for _, target in Targets.all() do
		if not target:IsDescendantOf(folder) then
			table.insert(list, target)
		end
	end
	return list
end

local function step()
	local started = os.clock()
	local context: EnemyBrain.Context? = nil
	for _, enemy in enemies do
		if started >= enemy.nextThinkAt then
			if not context then
				context = { now = started, living = livingPlayers(), ignore = nonBlocking() }
			end
			EnemyBrain.think(enemy, context :: EnemyBrain.Context)
			local wait = if enemy.asleep then EnemiesConfig.SLEEP_CHECK_INTERVAL else EnemiesConfig.THINK_INTERVAL
			enemy.nextThinkAt = started + wait
		end
	end
	local finished = os.clock()
	aiTime += finished - started

	if finished - windowStart >= 1 then
		local awake = 0
		for _, enemy in enemies do
			if not enemy.asleep then
				awake += 1
			end
		end
		Workspace:SetAttribute(Enemies.AWAKE_ATTRIBUTE, awake)
		Workspace:SetAttribute(Enemies.TOTAL_ATTRIBUTE, #enemies)
		Workspace:SetAttribute(Enemies.AI_TIME_ATTRIBUTE, aiTime * 1000 / (finished - windowStart))
		aiTime = 0
		windowStart = finished
	end
end

-- The enemies of a spawn point that was removed go with it: no loot, no respawn.
local function removePoint(part: Instance)
	for _, enemy in table.clone(enemies) do
		local point = pointOf[enemy]
		if point and point.part == part then
			EnemyBrain.die(enemy)
			removeFromList(enemy)
			enemy.model:Destroy()
		end
	end
end

-- How many enemies of this spawn point are alive (camps, US-047).
function EnemyService.livingAt(part: BasePart): number
	local count = 0
	for _, enemy in enemies do
		local point = pointOf[enemy]
		if point and point.part == part then
			count += 1
		end
	end
	return count
end

-- Brings a spawn point's enemies now (a camp coming back, US-047).
function EnemyService.respawn(part: BasePart)
	addPoint(part)
end

-- Calls `listener` after every kill by players.
function EnemyService.onKilled(listener: (kill: Kill) -> ())
	table.insert(killListeners, listener)
end

function EnemyService:Init()
	folder = Instance.new("Folder")
	folder.Name = "Enemies"
	folder.Parent = Workspace
end

function EnemyService:Start()
	DamageService.onDamaged(function(target, attacker)
		local enemy = byModel[target]
		if enemy and attacker then
			EnemyBrain.provoke(enemy, attacker)
		end
	end)
	DamageService.onKnockedDown(function(target, contributions)
		local enemy = byModel[target]
		if enemy then
			finish(enemy, contributions)
		end
	end)

	CollectionService:GetInstanceAddedSignal(Enemies.SPAWN_TAG):Connect(addPoint)
	CollectionService:GetInstanceRemovedSignal(Enemies.SPAWN_TAG):Connect(removePoint)
	local placeHasPoints = false
	for _, part in CollectionService:GetTagged(Enemies.SPAWN_TAG) do
		addPoint(part)
		-- Test content made by other services (camps) does not count as the place's own points.
		if part:GetAttribute("TestContent") ~= true then
			placeHasPoints = true
		end
	end
	if not placeHasPoints then
		createTestArea()
	end
	if DebugConfig.EXTRA_TEST_ENEMIES > 0 then
		createStressTest(DebugConfig.EXTRA_TEST_ENEMIES)
	end

	RunService.Heartbeat:Connect(step)
end

return EnemyService
