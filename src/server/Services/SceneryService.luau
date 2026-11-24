--!strict
--[[
	SceneryService.luau
	Builds the provisional scenery (US-054) when the place uses the test layout of the zones (no zone
	regions made in Studio) and has no scenery yet (tag Scenery). It runs after every service has
	started, so it knows where the test content stands (enemies, camps, dungeon entrances, the chest,
	the dummies) and keeps clear of it, and of the city. It also paints the Baseplate of the test
	place as a meadow.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Enemies = require(ReplicatedStorage.Shared.Enemies)
local SceneryConfig = require(ReplicatedStorage.Shared.Config.Scenery)
local World = require(ReplicatedStorage.Shared.World)
local ZonesConfig = require(ReplicatedStorage.Shared.Config.Zones)
local SceneryBuilder = require(script.Parent.Parent.SceneryBuilder)

-- The folder of the test layout of the zones (ZoneService).
local TEST_LAYOUT_NAME = "ZoneTestLayout"

local SceneryService = {}

-- The spawn's frame on the ground (its bottom face), where the test layout starts.
local function originFrame(): CFrame
	local spawnLocation = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if spawnLocation and spawnLocation:IsA("BasePart") then
		local ground = spawnLocation.Position - Vector3.new(0, spawnLocation.Size.Y / 2, 0)
		return CFrame.new(ground) * spawnLocation.CFrame.Rotation
	end
	return CFrame.new()
end

-- Every gameplay point to keep clear, with its radius.
local function gameplayPoints(): { SceneryBuilder.Avoid }
	local points: { SceneryBuilder.Avoid } = {}
	local function add(instance: Instance, radius: number)
		if instance:IsA("BasePart") then
			table.insert(points, { position = instance.Position, radius = radius })
		elseif instance:IsA("Model") then
			table.insert(points, { position = instance:GetPivot().Position, radius = radius })
		else
			for _, descendant in instance:GetDescendants() do
				if descendant:IsA("BasePart") then
					table.insert(points, { position = descendant.Position, radius = radius })
				end
			end
		end
	end
	for tag, radius in SceneryConfig.AVOID_TAGS do
		for _, instance in CollectionService:GetTagged(tag) do
			add(instance, radius)
		end
	end
	for _, descendant in Workspace:GetDescendants() do
		if descendant:IsA("SpawnLocation") then
			add(descendant, SceneryConfig.CLEAR_SPAWN)
		end
	end
	return points
end

-- The center of each camp: the middle of its enemy spawns.
local function campCenters(): { Vector3 }
	local centers: { Vector3 } = {}
	for _, camp in CollectionService:GetTagged(SceneryConfig.CAMP_TAG) do
		local sum, count = Vector3.zero, 0
		for _, descendant in camp:GetDescendants() do
			if descendant:IsA("BasePart") and CollectionService:HasTag(descendant, Enemies.SPAWN_TAG) then
				sum += descendant.Position
				count += 1
			end
		end
		if count > 0 then
			table.insert(centers, sum / count)
		end
	end
	return centers
end

-- The box of the city (its walls and gates), if there is one.
local function cityBox(): { cframe: CFrame, size: Vector3 }?
	for _, city in CollectionService:GetTagged(World.CITY_TAG) do
		if city:IsA("Model") then
			local cframe, size = city:GetBoundingBox()
			return { cframe = cframe, size = size }
		end
	end
	return nil
end

-- The Baseplate of the test place becomes the meadow (its grid texture hidden).
local function paintMeadow()
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Material = SceneryConfig.MEADOW.material
		baseplate.Color = SceneryConfig.MEADOW.color
		for _, child in baseplate:GetChildren() do
			if child:IsA("Decal") then
				child.Transparency = 1
			end
		end
	end
end

local function build()
	paintMeadow()
	local zones = table.clone(ZonesConfig.TEST_LAYOUT.zones)
	table.sort(zones, function(a, b)
		return a.from < b.from
	end)
	local folder = SceneryBuilder.build({
		origin = originFrame(),
		depth = ZonesConfig.TEST_LAYOUT.depth,
		zones = zones,
		avoid = gameplayPoints(),
		city = cityBox(),
		camps = campCenters(),
	})
	folder.Parent = Workspace
end

function SceneryService:Start()
	if not SceneryConfig.BUILD_TEST_SCENERY or not Workspace:FindFirstChild(TEST_LAYOUT_NAME) then
		return
	end
	if #CollectionService:GetTagged(World.SCENERY_TAG) > 0 then
		return
	end
	-- After every service's Start, so their test content is already in place.
	task.defer(build)
end

return SceneryService
