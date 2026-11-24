--!strict
--[[
	CityService.luau
	Builds the provisional city of Stardawn (US-052) on each City zone of the place, when the place has
	no city yet (tag CityModel). A city made in Studio, or the provisional one frozen there, is kept as
	it is. The city stands on the ground at the zone's center, its main street along the zone's X.
	Inside each gate it shows the zone beyond it. The center of the zone, where players come back to
	the city, stays on the main street.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CityConfig = require(ReplicatedStorage.Shared.Config.City)
local World = require(ReplicatedStorage.Shared.World)
local Zones = require(ReplicatedStorage.Shared.Zones)
local CityBuilder = require(script.Parent.Parent.CityBuilder)
local ZoneService = require(script.Parent.ZoneService)

-- Studs past the zone's edge where the zone beyond a gate is read.
local BEYOND = 20

local CityService = {}

-- The zone's center on the ground, turned like the zone (without tilt).
local function groundFrame(region: BasePart): CFrame
	local top = region.Position + Vector3.new(0, region.Size.Y / 2, 0)
	local hit = Workspace:Raycast(top, Vector3.new(0, -region.Size.Y - 100, 0))
	local y = if hit then hit.Position.Y else region.Position.Y - region.Size.Y / 2
	local look = region.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.01 then
		flat = Vector3.new(0, 0, -1)
	end
	local center = Vector3.new(region.Position.X, y, region.Position.Z)
	return CFrame.lookAt(center, center + flat.Unit)
end

-- What a gate shows inside: the zone `distance` studs from the city's center along its X (game text).
local function beyond(city: CFrame, distance: number): string
	local zone = ZoneService.zoneAt(city * Vector3.new(distance, 0, 0))
	return `{zone.name}\n{zone.rules.name} · T{zone.tier}`
end

function CityService:Start()
	if not CityConfig.BUILD_PROVISIONAL or #CollectionService:GetTagged(World.CITY_TAG) > 0 then
		return
	end
	for _, region in CollectionService:GetTagged(Zones.TAG) do
		if
			region:IsA("BasePart")
			and region:GetAttribute("Zone") == "City"
			and region:GetAttribute("Dungeon") ~= true
		then
			local city = groundFrame(region)
			local reach = region.Size.X / 2 + BEYOND
			local model = CityBuilder.build(city, { eastText = beyond(city, reach), westText = beyond(city, -reach) })
			model.Parent = Workspace
		end
	end
end

return CityService
