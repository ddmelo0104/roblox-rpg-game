--!strict
--[[
	TrainingDummyService.luau
	Training dummies of the prototype (US-009, US-012). If the place has no model with the target
	tag, it creates a row of simple dummies in front of the spawn, to test the target lock and the
	abilities (Config/Training says how many and the spacing between them).
	When a dummy's health reaches zero, it comes back after Config/Training.DUMMY_RESPAWN_TIME.
	It is a placeholder: real models are built in Studio and only need the tag (Shared.Targets.TAG).
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Targets = require(ReplicatedStorage.Shared.Targets)
local TrainingConfig = require(ReplicatedStorage.Shared.Config.Training)

-- Visual only: the dummies' color and the name shown above them (player-facing, in Portuguese).
local DUMMY_COLOR = Color3.fromRGB(196, 160, 110)
local DISPLAY_NAME = "Boneco de treino"

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

local function newPart(name: string, size: Vector3, center: Vector3, model: Model): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = CFrame.new(center)
	part.Anchored = true
	part.Color = DUMMY_COLOR
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model
	return part
end

-- Builds a dummy with its feet on `ground` and puts it in the Workspace with the target tag.
local function createDummy(ground: Vector3)
	local model = Instance.new("Model")
	model.Name = "TrainingDummy"

	newPart("LeftLeg", Vector3.new(1, 2, 1), ground + Vector3.new(-0.5, 1, 0), model)
	newPart("RightLeg", Vector3.new(1, 2, 1), ground + Vector3.new(0.5, 1, 0), model)
	newPart("Torso", Vector3.new(2, 2, 1), ground + Vector3.new(0, 3, 0), model)
	newPart("Head", Vector3.new(2, 1, 1), ground + Vector3.new(0, 4.5, 0), model)
	local root = newPart("HumanoidRootPart", Vector3.new(2, 2, 1), ground + Vector3.new(0, 3, 0), model)
	root.Transparency = 1
	root.CanCollide = false
	model.PrimaryPart = root

	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayName = DISPLAY_NAME
	humanoid.RequiresNeck = false
	humanoid.MaxHealth = TrainingConfig.DUMMY_HEALTH
	humanoid.Health = TrainingConfig.DUMMY_HEALTH
	humanoid.Parent = model

	CollectionService:AddTag(model, Targets.TAG)
	model.Parent = Workspace

	local respawning = false
	humanoid.HealthChanged:Connect(function(health)
		if health > 0 or respawning then
			return
		end
		respawning = true
		task.delay(TrainingConfig.DUMMY_RESPAWN_TIME, function()
			model:Destroy()
			createDummy(ground)
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
		createDummy(groundBelow(center + side * offset))
	end
end

return TrainingDummyService
