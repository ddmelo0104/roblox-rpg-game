--!strict
--[[
	SparringDummy.luau
	Behavior of the sparring dummy (US-013): it strikes the nearest player in range after a wind-up
	that can be read (it turns to the player and its torso turns red), so players can train the
	timing of the dodge and the parry. The strike goes through DefenseService, and a stunned dummy (a
	successful parry) does not start a new strike. The numbers live in Config/Training.
	TrainingDummyService creates the dummy and starts this behavior.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Abilities = require(ReplicatedStorage.Shared.Abilities)
local CombatConfig = require(ReplicatedStorage.Shared.Config.Combat)
local Status = require(ReplicatedStorage.Shared.Status)
local Targets = require(ReplicatedStorage.Shared.Targets)
local TrainingConfig = require(ReplicatedStorage.Shared.Config.Training)
local DefenseService = require(script.Parent.Services.DefenseService)

-- Visual only: the torso color during the wind-up, and how often an idle dummy looks for players.
local WINDUP_COLOR = Color3.fromRGB(220, 60, 60)
local IDLE_CHECK_INTERVAL = 0.25

local SparringDummy = {}

local function livingRoot(player: Player): BasePart?
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function isInReach(origin: Vector3, root: BasePart, margin: number): boolean
	return Abilities.isInRadius(
		origin,
		root.Position,
		TrainingConfig.SPARRING_RANGE,
		margin,
		CombatConfig.MAX_HIT_HEIGHT
	)
end

-- The nearest living player in reach of `origin`, or nil.
local function nearestPlayer(origin: Vector3): Player?
	local best: Player? = nil
	local bestDistance = math.huge
	for _, player in Players:GetPlayers() do
		local root = livingRoot(player)
		if root and isInReach(origin, root, 0) then
			local distance = (root.Position - origin).Magnitude
			if distance < bestDistance then
				best = player
				bestDistance = distance
			end
		end
	end
	return best
end

-- Turns the (anchored) dummy to look at `point`, on the ground plane only.
local function face(model: Model, point: Vector3)
	local pivot = model:GetPivot()
	local flatPoint = Vector3.new(point.X, pivot.Position.Y, point.Z)
	if (flatPoint - pivot.Position).Magnitude > 0.1 then
		model:PivotTo(CFrame.lookAt(pivot.Position, flatPoint))
	end
end

-- One strike: wind-up, then the hit if the player is still in reach (with the lag margin, ADR-009).
local function strike(model: Model, torso: BasePart, target: Player)
	local root = livingRoot(target)
	if root then
		face(model, root.Position)
	end
	local restColor = torso.Color
	torso.Color = WINDUP_COLOR
	task.wait(TrainingConfig.SPARRING_WINDUP)
	torso.Color = restColor

	local origin = Targets.position(model)
	root = livingRoot(target)
	if
		model.Parent
		and Targets.isAlive(model)
		and origin
		and root
		and isInReach(origin, root, CombatConfig.LAG_MARGIN)
	then
		task.spawn(DefenseService.receiveHit, target, TrainingConfig.SPARRING_DAMAGE, "Melee", model)
	end
end

-- Starts the attack loop of one sparring dummy. It stops when the dummy dies or is destroyed.
function SparringDummy.start(model: Model)
	local torso = model:FindFirstChild("Torso")
	if not torso or not torso:IsA("BasePart") then
		return
	end
	task.spawn(function()
		while model.Parent and Targets.isAlive(model) do
			local origin = Targets.position(model)
			local target = if origin and not Status.isStunned(model) then nearestPlayer(origin) else nil
			if target then
				strike(model, torso, target)
				task.wait(TrainingConfig.SPARRING_COOLDOWN)
			else
				task.wait(IDLE_CHECK_INTERVAL)
			end
		end
	end)
end

return table.freeze(SparringDummy)
