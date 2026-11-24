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

-- Steps (studs) of the walk out of the city that finds the zone beyond a gate, how far it goes,
-- and how far past the city's edge the zone is read.
local STEP = 25
local MAX_WALK = 4000
local BEYOND = 40

-- The way out of each gate, in the city's frame.
local OUTWARD: { [string]: Vector3 } = {
	East = Vector3.new(1, 0, 0),
	West = Vector3.new(-1, 0, 0),
	South = Vector3.new(0, 0, 1),
	North = Vector3.new(0, 0, -1),
}

local CityService = {}

-- The zone's center on the ground, turned like the zone (without tilt).
local function groundFrame(region: BasePart): CFrame
	local bottom, top = Zones.verticalSpan(region)
	local from = Vector3.new(region.Position.X, top, region.Position.Z)
	local hit = Workspace:Raycast(from, Vector3.new(0, bottom - top - 100, 0))
	local y = if hit then hit.Position.Y else bottom
	local look = region.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.01 then
		flat = Vector3.new(0, 0, -1)
	end
	local center = Vector3.new(region.Position.X, y, region.Position.Z)
	return CFrame.lookAt(center, center + flat.Unit)
end

-- What a gate shows inside (game text): the zone met walking out of the city that way, whatever the
-- shape of the city's zone.
local function beyond(city: CFrame, direction: Vector3): string?
	local here = ZoneService.zoneAt(city.Position)
	local way = city:VectorToWorldSpace(direction)
	for distance = STEP, MAX_WALK, STEP do
		if not Zones.same(ZoneService.zoneAt(city.Position + way * distance), here) then
			local zone = ZoneService.zoneAt(city.Position + way * (distance + BEYOND))
			if zone.region == nil then
				return nil -- the edge of the map
			end
			return `{zone.name}\n{zone.rules.name} · T{zone.tier}`
		end
	end
	return nil
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
			local texts: { [string]: string } = {}
			for _, gate in CityConfig.GATES do
				local direction = OUTWARD[gate.side]
				local text = if direction then beyond(city, direction) else nil
				if text then
					texts[gate.side] = text
				end
			end
			local model = CityBuilder.build(city, { gateTexts = texts })
			model.Parent = Workspace
		end
	end
end

return CityService
