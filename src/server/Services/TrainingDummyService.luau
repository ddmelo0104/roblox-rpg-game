--!strict
--[[
	TrainingDummyService.luau
	Training dummies of the prototype (US-009, US-012, US-013). If the place has no model with the
	target tag, it creates a row of simple dummies in front of the spawn, to test the target lock and
	the abilities, plus a sparring dummy at the end of the row that strikes back, to train the dodge
	and the parry (Config/Training says how many, where and how they behave).
	When a dummy's health reaches zero, it comes back after Config/Training.DUMMY_RESPAWN_TIME.
	It is a placeholder: real models are built in Studio and only need the tag (Shared.Targets.TAG).
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Targets = require(ReplicatedStorage.Shared.Targets)
local TrainingConfig = require(ReplicatedStorage.Shared.Config.Training)
local SparringDummy = require(script.Parent.Parent.SparringDummy)

-- Visual only: the dummies' colors and the names shown above them (player-facing, in Portuguese).
local DUMMY_COLOR = Color3.fromRGB(196, 160, 110)
local SPARRING_COLOR = Color3.fromRGB(150, 120, 90)
local DISPLAY_NAME = "Boneco de treino"
local SPARRING_DISPLAY_NAME = "Boneco que ataca"

type Kind = {
	name: string,
	displayName: string,
	color: Color3,
	-- Runs on every new copy of the dummy (also after a respawn).
	onSpawn: ((model: Model) -> ())?,
}

local TRAINING: Kind = { name = "TrainingDummy", displayName = DISPLAY_NAME, color = DUMMY_COLOR }
local SPARRING: Kind = {
	name = "SparringDummy",
	displayName = SPARRING_DISPLAY_NAME,
	color = SPARRING_COLOR,
	onSpawn = SparringDummy.start,
}

local TrainingDummyService = {}

-- The ground right below a point, or the point itself if there is nothing below it.
local function groundBelow(point: Vector3): Vector3
	local result = Workspace:Raycast(point + Vector3.new(0, 50, 0), Vector3.new(0, -200, 0))
	if result then
		return result.Position
	end
	return point
end

-- The center of the row, in front of the SpawnLocation (or of the origin, if the place has no
-- spawn), and the row's side-to-side direction.
local function rowCenter(): (Vector3, Vector3)
	local spawnLocation = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if spawnLocation and spawnLocation:IsA("BasePart") then
		local ahead = spawnLocation.CFrame.LookVector * TrainingConfig.DISTANCE_FROM_SPAWN
		return spawnLocation.Position + ahead, spawnLocation.CFrame.RightVector
	end
	return Vector3.new(0, 0, -TrainingConfig.DISTANCE_FROM_SPAWN), Vector3.new(1, 0, 0)
end

local function newPart(name: string, size: Vector3, center: Vector3, color: Color3, model: Model): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = CFrame.new(center)
	part.Anchored = true
	part.Color = color
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model
	return part
end

-- Builds a dummy of the given kind with its feet on `ground`, puts it in the Workspace with the
-- target tag, and brings it back after it is knocked down.
local function createDummy(kind: Kind, ground: Vector3)
	local model = Instance.new("Model")
	model.Name = kind.name

	newPart("LeftLeg", Vector3.new(1, 2, 1), ground + Vector3.new(-0.5, 1, 0), kind.color, model)
	newPart("RightLeg", Vector3.new(1, 2, 1), ground + Vector3.new(0.5, 1, 0), kind.color, model)
	newPart("Torso", Vector3.new(2, 2, 1), ground + Vector3.new(0, 3, 0), kind.color, model)
	newPart("Head", Vector3.new(2, 1, 1), ground + Vector3.new(0, 4.5, 0), kind.color, model)
	local root = newPart("HumanoidRootPart", Vector3.new(2, 2, 1), ground + Vector3.new(0, 3, 0), kind.color, model)
	root.Transparency = 1
	root.CanCollide = false
	model.PrimaryPart = root

	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayName = kind.displayName
	humanoid.RequiresNeck = false
	humanoid.MaxHealth = TrainingConfig.DUMMY_HEALTH
	humanoid.Health = TrainingConfig.DUMMY_HEALTH
	humanoid.Parent = model

	CollectionService:AddTag(model, Targets.TAG)
	model.Parent = Workspace
	if kind.onSpawn then
		kind.onSpawn(model)
	end

	local respawning = false
	humanoid.HealthChanged:Connect(function(health)
		if health > 0 or respawning then
			return
		end
		respawning = true
		task.delay(TrainingConfig.DUMMY_RESPAWN_TIME, function()
			model:Destroy()
			createDummy(kind, ground)
		end)
	end)
end

function TrainingDummyService:Start()
	if #Targets.all() > 0 then
		return -- the place already has targets built in Studio
	end
	local center, side = rowCenter()
	local count = TrainingConfig.DUMMY_COUNT
	for i = 1, count do
		local offset = (i - (count + 1) / 2) * TrainingConfig.DUMMY_SPACING
		createDummy(TRAINING, groundBelow(center + side * offset))
	end

	-- The sparring dummy stands at the end of the row, far enough not to reach the other dummies' area.
	local rowHalfWidth = (count - 1) / 2 * TrainingConfig.DUMMY_SPACING
	createDummy(SPARRING, groundBelow(center + side * (rowHalfWidth + TrainingConfig.SPARRING_GAP)))
end

return TrainingDummyService
