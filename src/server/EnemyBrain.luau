--!strict
--[[
	EnemyBrain.luau
	What an enemy does (US-025, US-027, US-028). EnemyService calls `think` once every
	Config/Enemies.THINK_INTERVAL for an awake enemy:
	- Idle, at home: it notices the nearest living player within its aggro range and in sight, or the
	  player who hits it (`provoke`), and chases them. With no player within SLEEP_RANGE it sleeps,
	  and EnemyService only checks it once in a while.
	- Chase: it walks to its target and attacks when in reach. An attack shows a warning (the torso
	  turns red for `windup` seconds) and then goes through DefenseService, so the dodge and the
	  parry work; a ranged shot is only avoided by the dodge. A stunned enemy (a successful parry)
	  stands still and does not attack.
	- Return: it gives up when its target is gone or too far from its home (leash), or when it tries
	  to walk but cannot move for STUCK_TIME (stuck on the terrain, or the target is somewhere it
	  cannot reach). A target that is just faster does not make it give up: the leash does. Going
	  home it is not a target; at home it heals fully and forgets the damage it took, so damage it
	  could not answer is worth nothing.
	- Dead: EnemyService handles the body and the loot; `blast` is the death explosion (US-028).
]]

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Abilities = require(ReplicatedStorage.Shared.Abilities)
local CombatConfig = require(ReplicatedStorage.Shared.Config.Combat)
local Enemies = require(ReplicatedStorage.Shared.Enemies)
local EnemiesConfig = require(ReplicatedStorage.Shared.Config.Enemies)
local Status = require(ReplicatedStorage.Shared.Status)
local Targets = require(ReplicatedStorage.Shared.Targets)
local DamageService = require(script.Parent.Services.DamageService)
local DefenseService = require(script.Parent.Services.DefenseService)

export type State = "Idle" | "Chase" | "Attack" | "Return" | "Dead"

export type Enemy = {
	model: Model,
	humanoid: Humanoid,
	root: BasePart,
	torso: BasePart,
	kind: Enemies.Kind,
	damage: number,
	-- How much the kind's base damage was multiplied (tier and elite), for the death blast.
	damageScale: number,
	-- Where the root stood when it appeared.
	home: CFrame,
	state: State,
	target: Player?,
	asleep: boolean,
	-- Times (os.clock) of the next decision and of the earliest next attack.
	nextThinkAt: number,
	nextAttackAt: number,
	-- Stuck check: where it was when it last moved STUCK_PROGRESS studs, and when that was.
	lastPosition: Vector3,
	progressAt: number,
	returnStartedAt: number,
}

-- A living player and the root of their character.
export type Living = { player: Player, root: BasePart }

-- What every decision of one frame shares: the time, the living players and what does not block
-- the sight (characters and targets: only the world does).
export type Context = {
	now: number,
	living: { Living },
	ignore: { Instance },
}

-- Visual only: the warning color, the shot of a ranged attack and the death blast.
local WINDUP_COLOR = Color3.fromRGB(220, 60, 60)
local SHOT_COLOR = Color3.fromRGB(255, 230, 150)
local SHOT_TIME = 0.15
local BLAST_COLOR = Color3.fromRGB(255, 90, 30)
local FLASH_TIME = 0.25

-- How close to home (studs) counts as having arrived.
local HOME_REACHED = 3

local EnemyBrain = {}

local function effectPart(shape: Enum.PartType, color: Color3, transparency: number): Part
	local part = Instance.new("Part")
	part.Shape = shape
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Transparency = transparency
	return part
end

local function drawShot(from: Vector3, to: Vector3)
	local length = (to - from).Magnitude
	local shot = effectPart(Enum.PartType.Block, SHOT_COLOR, 0)
	shot.Size = Vector3.new(0.15, 0.15, length)
	shot.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -length / 2)
	shot.Parent = Workspace
	Debris:AddItem(shot, SHOT_TIME)
end

local function livingOf(context: Context, player: Player): Living?
	for _, living in context.living do
		if living.player == player then
			return living
		end
	end
	return nil
end

-- The living root of the player's character right now, or nil.
local function currentRoot(player: Player): BasePart?
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function isNearHome(enemy: Enemy, position: Vector3): boolean
	return (position - enemy.home.Position).Magnitude <= EnemiesConfig.LEASH_RANGE
end

-- The nearest living player the enemy notices: within its aggro range, near its home and in sight.
local function findTarget(enemy: Enemy, context: Context): Living?
	local origin = enemy.root.Position
	local best: Living? = nil
	local bestDistance = enemy.kind.aggroRange
	for _, living in context.living do
		local position = living.root.Position
		local distance = (position - origin).Magnitude
		if
			distance <= bestDistance
			and isNearHome(enemy, position)
			and Targets.hasLineOfSight(enemy.torso.Position, position, context.ignore)
		then
			best = living
			bestDistance = distance
		end
	end
	return best
end

-- Whether a target at `position` is in reach; a ranged enemy also needs to see it. To decide to
-- attack (`hitting` false), a ranged enemy uses a bit less than its range (RANGED_STOP_FRACTION), so
-- the shot still lands if the target steps back; when the hit lands (`hitting` true), the full
-- range plus the lag margin counts (ADR-009).
local function isInReach(enemy: Enemy, position: Vector3, hitting: boolean, ignore: { Instance }): boolean
	local ranged = enemy.kind.attack == "Ranged"
	local reach = enemy.kind.range * (if ranged and not hitting then EnemiesConfig.RANGED_STOP_FRACTION else 1)
	local margin = if hitting then CombatConfig.LAG_MARGIN else 0
	if not Abilities.isInRadius(enemy.root.Position, position, reach, margin, CombatConfig.MAX_HIT_HEIGHT) then
		return false
	end
	return not ranged or Targets.hasLineOfSight(enemy.torso.Position, position, ignore)
end

local function stop(enemy: Enemy)
	enemy.humanoid:MoveTo(enemy.root.Position)
end

local function face(enemy: Enemy, point: Vector3)
	local position = enemy.root.Position
	local flat = Vector3.new(point.X, position.Y, point.Z)
	if (flat - position).Magnitude > 0.1 then
		enemy.root.CFrame = CFrame.lookAt(position, flat)
	end
end

local function startChase(enemy: Enemy, player: Player, now: number)
	enemy.state = "Chase"
	enemy.target = player
	enemy.asleep = false
	enemy.lastPosition = enemy.root.Position
	enemy.progressAt = now
end

local function startReturn(enemy: Enemy, now: number)
	enemy.state = "Return"
	enemy.target = nil
	enemy.returnStartedAt = now
	CollectionService:RemoveTag(enemy.model, Targets.TAG)
	enemy.humanoid:MoveTo(enemy.home.Position)
end

local function arriveHome(enemy: Enemy)
	enemy.humanoid.Health = enemy.humanoid.MaxHealth
	DamageService.forget(enemy.model)
	CollectionService:AddTag(enemy.model, Targets.TAG)
	enemy.state = "Idle"
end

-- One attack on `player`: the warning, then the hit if they are still in reach (with the lag
-- margin, ADR-009) and the enemy was not stunned or killed meanwhile. Yields.
local function attack(enemy: Enemy, player: Player, now: number)
	enemy.state = "Attack"
	enemy.nextAttackAt = now + enemy.kind.interval
	stop(enemy)
	local root = currentRoot(player)
	if root then
		face(enemy, root.Position)
	end
	local restColor = enemy.torso.Color
	enemy.torso.Color = WINDUP_COLOR
	task.wait(enemy.kind.windup)
	enemy.torso.Color = restColor
	if enemy.state ~= "Attack" then
		return -- it died meanwhile
	end
	enemy.state = "Chase"
	if Status.isStunned(enemy.model) then
		return
	end
	root = currentRoot(player)
	if not root then
		return
	end
	local character = player.Character :: Model
	if not isInReach(enemy, root.Position, true, { enemy.model, character }) then
		return
	end
	if enemy.kind.attack == "Ranged" then
		drawShot(enemy.torso.Position, root.Position)
	end
	task.spawn(DefenseService.receiveHit, player, enemy.damage, enemy.kind.attack, enemy.model)
end

-- One decision. Called by EnemyService; does not yield (an attack runs in its own thread).
function EnemyBrain.think(enemy: Enemy, context: Context)
	local now = context.now
	if enemy.state == "Dead" or enemy.state == "Attack" then
		return
	end

	if enemy.state == "Return" then
		local away = (enemy.root.Position - enemy.home.Position).Magnitude
		if away <= HOME_REACHED or now - enemy.returnStartedAt > EnemiesConfig.RETURN_TIMEOUT then
			if away > HOME_REACHED then
				enemy.model:PivotTo(enemy.home)
			end
			arriveHome(enemy)
		else
			enemy.humanoid:MoveTo(enemy.home.Position)
		end
		return
	end

	if enemy.state == "Idle" then
		local someoneNear = false
		for _, living in context.living do
			if (living.root.Position - enemy.root.Position).Magnitude <= EnemiesConfig.SLEEP_RANGE then
				someoneNear = true
				break
			end
		end
		enemy.asleep = not someoneNear
		local found = if someoneNear then findTarget(enemy, context) else nil
		if not found then
			return
		end
		startChase(enemy, found.player, now)
	end

	-- Chase: keep the target while it is alive and near home; otherwise take another or go home.
	local living = if enemy.target then livingOf(context, enemy.target) else nil
	if not living or not isNearHome(enemy, living.root.Position) then
		living = findTarget(enemy, context)
		if not living then
			startReturn(enemy, now)
			return
		end
		startChase(enemy, living.player, now)
	end
	local target = living :: Living
	if Status.isStunned(enemy.model) then
		stop(enemy)
		return
	end

	local position = target.root.Position
	if isInReach(enemy, position, false, context.ignore) then
		enemy.lastPosition = enemy.root.Position
		enemy.progressAt = now
		if now >= enemy.nextAttackAt then
			task.spawn(attack, enemy, target.player, now)
		else
			stop(enemy)
			face(enemy, position)
		end
		return
	end

	-- Out of reach: walk closer, and give up if it has not been able to move for too long.
	if (enemy.root.Position - enemy.lastPosition).Magnitude >= EnemiesConfig.STUCK_PROGRESS then
		enemy.lastPosition = enemy.root.Position
		enemy.progressAt = now
	elseif now - enemy.progressAt > EnemiesConfig.STUCK_TIME then
		startReturn(enemy, now)
		return
	end
	enemy.humanoid:MoveTo(position)
end

-- A player hit the enemy: an idle enemy chases them at once.
function EnemyBrain.provoke(enemy: Enemy, player: Player)
	if enemy.state == "Idle" then
		startChase(enemy, player, os.clock())
		enemy.nextThinkAt = 0
	end
end

-- The enemy died: it stops doing anything.
function EnemyBrain.die(enemy: Enemy)
	enemy.state = "Dead"
	enemy.target = nil
	stop(enemy)
end

-- The death explosion (US-028): a red circle grows on `ground` for the blast's delay, then every
-- living player inside takes the damage as a ranged hit (only the dodge avoids it). Yields.
function EnemyBrain.blast(enemy: Enemy, ground: Vector3)
	local blast = enemy.kind.deathBlast
	if not blast then
		return
	end
	local disc = effectPart(Enum.PartType.Cylinder, BLAST_COLOR, 0.5)
	disc.Size = Vector3.new(0.2, 1, 1)
	disc.CFrame = CFrame.new(ground + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	disc.Parent = Workspace
	local diameter = blast.radius * 2
	TweenService:Create(disc, TweenInfo.new(blast.delay), { Size = Vector3.new(0.2, diameter, diameter) }):Play()
	task.wait(blast.delay)
	disc:Destroy()

	local flash = effectPart(Enum.PartType.Ball, BLAST_COLOR, 0.6)
	flash.Size = Vector3.new(diameter, diameter, diameter)
	flash.Position = ground
	flash.Parent = Workspace
	Debris:AddItem(flash, FLASH_TIME)

	local damage = blast.damage * enemy.damageScale
	for _, player in Players:GetPlayers() do
		local root = currentRoot(player)
		if
			root
			and Abilities.isInRadius(
				ground,
				root.Position,
				blast.radius,
				CombatConfig.LAG_MARGIN,
				CombatConfig.MAX_HIT_HEIGHT
			)
		then
			task.spawn(DefenseService.receiveHit, player, damage, "Ranged", nil)
		end
	end
end

return table.freeze(EnemyBrain)
