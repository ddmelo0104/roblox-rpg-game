--!strict
--[[
	StardawnGenerator.luau
	Builds the world of Stardawn in Studio (US-055), from Config/World. It makes four things:
	1. The terrain: the relief of each zone, the flat grounds of the city and the spawn, the paths
	   and the mountains around the zones, with each zone's materials, rock on steep slopes and snow
	   on the peaks.
	2. The zone regions (a round region per circle; the parts of a zone share its ZoneId, US-056),
	   the return points, and the SpawnLocation at the far end of the Blue valley.
	3. The gameplay points: groups of enemies, camps with tents and a campfire, solo dungeon
	   entrances and the group dungeon's entrance.
	4. Nature: trees, bushes, rocks, crystals, ruins, stone spires, dead trees and watchtowers.
	First it removes what an earlier run made (tag GeneratedWorld) and clears the terrain. It also
	removes the test place's Baseplate and anything frozen from the flat test layout.

	Run it through WorldTools.Run from the command bar, in Edit mode, then save the place. The world
	lives in the place, as maps do (rule 5); the city, the light and the systems come from the code
	when the game runs.
]]

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local CampsConfig = require(ReplicatedStorage.Shared.Config.Camps)
local Enemies = require(ReplicatedStorage.Shared.Enemies)
local SceneryConfig = require(ReplicatedStorage.Shared.Config.Scenery)
local World = require(ReplicatedStorage.Shared.World)
local Zones = require(ReplicatedStorage.Shared.Zones)
local Props = require(ServerScriptService.Server.Props)

-- Everything a run makes carries this tag, so the next run removes it first.
local GENERATED_TAG = "GeneratedWorld"
-- Tags the services read (DungeonService, GroupDungeonService, CampService).
local ENTRANCE_TAG = "DungeonEntrance"
local GROUP_ENTRANCE_TAG = "GroupDungeonEntrance"
local CAMP_TAG = SceneryConfig.CAMP_TAG

local VOXEL = 4
local AIR = Enum.Material.Air
-- Under the surface layers, the ground is rock.
local DEEP = Enum.Material.Rock
-- Tries to find a free spot for one thing before giving up on it.
local SPOT_TRIES = 40
-- Studs between two samples when walking along a path, and the size of the cells that count the
-- area of each zone.
local PATH_STEP = 10
local AREA_CELL = 64
-- Cells of the grid that keeps nature items apart.
local NATURE_CELL = 32

type Spot = { x: number, z: number, radius: number }

local Generator = {}

local function log(message: string)
	print(`[StardawnGenerator] {message}`)
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- An invisible anchored part that only marks a place.
local function marker(parent: Instance, name: string, position: Vector3, size: Vector3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = CFrame.new(position)
	part.Anchored = true
	part.Transparency = 1
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = parent
	return part
end

local function folderIn(parent: Instance, name: string): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function zoneOfKind(config: any, kind: string): any?
	for _, zone in config.ZONES do
		if zone.kind == kind then
			return zone
		end
	end
	return nil
end

-- The box around a zone's circles: min x, min z, max x, max z.
local function zoneBox(zone: any): (number, number, number, number)
	local minX, minZ, maxX, maxZ = math.huge, math.huge, -math.huge, -math.huge
	for _, circle in zone.circles do
		minX = math.min(minX, circle[1] - circle[3])
		maxX = math.max(maxX, circle[1] + circle[3])
		minZ = math.min(minZ, circle[2] - circle[3])
		maxZ = math.max(maxZ, circle[2] + circle[3])
	end
	return minX, minZ, maxX, maxZ
end

local function slopeAt(sampler: any, x: number, z: number): number
	local step = 6
	local dx = (sampler.height(x + step, z) - sampler.height(x - step, z)) / (2 * step)
	local dz = (sampler.height(x, z + step) - sampler.height(x, z - step)) / (2 * step)
	return math.deg(math.atan(math.sqrt(dx * dx + dz * dz)))
end

-- Removes what an earlier run made, the Baseplate and anything frozen from the flat test layout.
local function clearOld(sampler: any)
	for _, instance in CollectionService:GetTagged(GENERATED_TAG) do
		instance:Destroy()
	end
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
		log("removed the Baseplate: the terrain is the ground now")
	end
	for _, scenery in CollectionService:GetTagged(World.SCENERY_TAG) do
		scenery:Destroy()
		log("removed scenery frozen from the flat test layout")
	end
	for _, city in CollectionService:GetTagged(World.CITY_TAG) do
		if city:IsA("Model") then
			local position = city:GetPivot().Position
			local zone = sampler.owner(position.X, position.Z)
			if not zone or zone.kind ~= "City" then
				city:Destroy()
				log("removed a city frozen outside the new city zone")
			end
		end
	end
	Workspace.Terrain:Clear()
end

-- One chunk of terrain: heights on a coarse grid, then each voxel column filled up to its height.
local function writeChunk(config: any, WorldShape: any, terrain: Terrain, x0: number, z0: number)
	local T = config.TERRAIN
	local count = T.CHUNK
	local size = count * VOXEL
	local grid = T.GRID
	local samples = size // grid + 1
	local sampler = WorldShape.sampler(config, x0, z0, x0 + size, z0 + size)

	local heights: { { number } } = table.create(samples)
	local low, high = math.huge, -math.huge
	for i = 1, samples do
		local row = table.create(samples)
		for k = 1, samples do
			local ground = sampler.height(x0 + (i - 1) * grid, z0 + (k - 1) * grid)
			row[k] = ground
			low = math.min(low, ground)
			high = math.max(high, ground)
		end
		heights[i] = row
	end

	local bottom = math.floor((low - T.THICKNESS) / VOXEL) * VOXEL
	local top = math.ceil((high + VOXEL) / VOXEL) * VOXEL
	local layers = (top - bottom) // VOXEL
	local materials: { { { Enum.Material } } } = table.create(count)
	local occupancies: { { { number } } } = table.create(count)
	for i = 1, count do
		local materialColumn = table.create(layers)
		local occupancyColumn = table.create(layers)
		for layer = 1, layers do
			materialColumn[layer] = table.create(count, AIR)
			occupancyColumn[layer] = table.create(count, 0)
		end
		materials[i] = materialColumn
		occupancies[i] = occupancyColumn
	end

	for i = 1, count do
		local x = x0 + (i - 0.5) * VOXEL
		local gx = (x - x0) / grid
		local gi = math.min(math.floor(gx), samples - 2)
		local tx = gx - gi
		local materialColumn = materials[i]
		local occupancyColumn = occupancies[i]
		for k = 1, count do
			local z = z0 + (k - 0.5) * VOXEL
			local gz = (z - z0) / grid
			local gk = math.min(math.floor(gz), samples - 2)
			local tz = gz - gk
			local h00, h10 = heights[gi + 1][gk + 1], heights[gi + 2][gk + 1]
			local h01, h11 = heights[gi + 1][gk + 2], heights[gi + 2][gk + 2]
			local ground = lerp(lerp(h00, h10, tx), lerp(h01, h11, tx), tz)
			local slopeX = ((h10 - h00) + (h11 - h01)) / (2 * grid)
			local slopeZ = ((h01 - h00) + (h11 - h10)) / (2 * grid)
			local slope = math.deg(math.atan(math.sqrt(slopeX * slopeX + slopeZ * slopeZ)))
			local surface = sampler.material(x, z, ground, slope)
			for layer = 1, layers do
				local fill = (ground - (bottom + (layer - 1) * VOXEL)) / VOXEL
				if fill <= 0 then
					break
				end
				occupancyColumn[layer][k] = math.min(fill, 1)
				materialColumn[layer][k] = if fill > 3 then DEEP else surface
			end
		end
	end

	terrain:WriteVoxels(
		Region3.new(Vector3.new(x0, bottom, z0), Vector3.new(x0 + size, top, z0 + size)),
		VOXEL,
		materials,
		occupancies
	)
end

local function writeTerrain(config: any, WorldShape: any): number
	local T = config.TERRAIN
	local terrain = Workspace.Terrain
	for name, color in T.COLORS do
		terrain:SetMaterialColor((Enum.Material :: any)[name], color)
	end
	local size = T.CHUNK * VOXEL
	local minX, minZ, maxX, maxZ = WorldShape.bounds(config)
	minX = math.floor((minX - T.MARGIN) / size) * size
	minZ = math.floor((minZ - T.MARGIN) / size) * size
	maxX = math.ceil((maxX + T.MARGIN) / size) * size
	maxZ = math.ceil((maxZ + T.MARGIN) / size) * size
	local whole = WorldShape.sampler(config, minX, minZ, maxX, maxZ)
	local chunks: { { number } } = {}
	local limit = -(T.MARGIN + size)
	for x0 = minX, maxX - size, size do
		for z0 = minZ, maxZ - size, size do
			if whole.inside(x0 + size / 2, z0 + size / 2) > limit then
				table.insert(chunks, { x0, z0 })
			end
		end
	end
	log(`writing the terrain: {#chunks} chunks of {size} x {size} studs`)
	local lastTenth = 0
	for index, chunk in chunks do
		writeChunk(config, WorldShape, terrain, chunk[1], chunk[2])
		if index % T.CHUNKS_PER_PAUSE == 0 then
			local tenth = math.floor(index / #chunks * 10)
			if tenth > lastTenth then
				lastTenth = tenth
				log(`terrain {tenth * 10}%`)
			end
			task.wait()
		end
	end
	return #chunks
end

-- A round region for each circle of each zone (US-056).
local function buildRegions(parent: Instance, config: any): number
	local folder = folderIn(parent, "Zones")
	local count = 0
	for _, zone in config.ZONES do
		for index, circle in zone.circles do
			local region = marker(
				folder,
				`{zone.name} {index}`,
				Vector3.new(circle[1], config.REGION_CENTER_Y, circle[2]),
				Vector3.new(4, 4, 4)
			)
			region:SetAttribute("Zone", zone.kind)
			region:SetAttribute("Tier", zone.tier)
			region:SetAttribute("ZoneName", zone.name)
			region:SetAttribute("ZoneId", zone.id)
			region:SetAttribute("Radius", circle[3])
			region:SetAttribute("Height", config.REGION_HEIGHT)
			CollectionService:AddTag(region, Zones.TAG)
			count += 1
		end
	end
	return count
end

-- The SpawnLocation at the far end of the Blue valley, facing the city.
local function placeSpawn(config: any, sampler: any)
	local spawn = config.SPAWN
	local ground = sampler.height(spawn.x, spawn.z)
	local found = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	local location: SpawnLocation
	if found and found:IsA("SpawnLocation") then
		location = found
	else
		location = Instance.new("SpawnLocation")
		location.Parent = Workspace
	end
	location.Anchored = true
	location.Size = Vector3.new(12, 1, 12)
	location.CFrame = CFrame.new(spawn.x, ground + 0.5, spawn.z)
end

-- Return points (EP-009): the city's center, by the spawn, and where each path enters a zone.
local function buildReturnPoints(parent: Instance, config: any, sampler: any): number
	local folder = folderIn(parent, "ReturnPoints")
	local count = 0
	local function point(x: number, z: number)
		local part = marker(folder, "ReturnPoint", Vector3.new(x, sampler.height(x, z) + 0.5, z), Vector3.new(4, 1, 4))
		CollectionService:AddTag(part, Zones.RETURN_TAG)
		count += 1
	end
	point(config.CITY.x, config.CITY.z)
	point(config.SPAWN.x, config.SPAWN.z - 16)
	local inside = math.ceil(config.RETURN_INSIDE / PATH_STEP)
	local done: { [string]: boolean } = {}
	for pathIndex, path in config.PATHS do
		local points: { { number } } = {}
		for index = 1, #path - 1 do
			local a, b = path[index], path[index + 1]
			local length = math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2)
			local steps = math.max(1, math.floor(length / PATH_STEP))
			for step = 0, steps - 1 do
				local t = step / steps
				table.insert(points, { lerp(a[1], b[1], t), lerp(a[2], b[2], t) })
			end
		end
		local previous: any = nil
		for index, spot in points do
			local zone = sampler.owner(spot[1], spot[2])
			if zone and previous and zone ~= previous and zone.kind ~= "City" then
				local key = `{pathIndex}:{zone.id}`
				local ahead = points[math.min(index + inside, #points)]
				if not done[key] and sampler.owner(ahead[1], ahead[2]) == zone then
					done[key] = true
					point(ahead[1], ahead[2])
				end
			end
			previous = zone
		end
	end
	return count
end

-- A free spot in `zone` for something of `radius`: in the zone, away from its edge, the paths, the
-- city and the spawn, on gentle ground, `spacing` studs from the others of `own` and clear of
-- every gameplay point in `all`. Nil if none was found.
local function findSpot(
	config: any,
	sampler: any,
	random: Random,
	zone: any,
	radius: number,
	own: { Spot },
	spacing: number,
	all: { Spot },
	pathClearance: number
): Vector3?
	local minX, minZ, maxX, maxZ = zoneBox(zone)
	local city, spawn = config.CITY, config.SPAWN
	for _ = 1, SPOT_TRIES do
		local x, z = random:NextNumber(minX, maxX), random:NextNumber(minZ, maxZ)
		local free = sampler.owner(x, z) == zone
			and sampler.inside(x, z) > radius + 80
			and sampler.pathDistance(x, z) > pathClearance + radius
			and (x - city.x) ^ 2 + (z - city.z) ^ 2 > config.CLEAR_CITY ^ 2
			and (x - spawn.x) ^ 2 + (z - spawn.z) ^ 2 > config.CLEAR_SPAWN ^ 2
		if free then
			for _, other in own do
				if (x - other.x) ^ 2 + (z - other.z) ^ 2 < spacing ^ 2 then
					free = false
					break
				end
			end
		end
		if free then
			for _, other in all do
				if (x - other.x) ^ 2 + (z - other.z) ^ 2 < (other.radius + radius + config.CLEAR_POINT) ^ 2 then
					free = false
					break
				end
			end
		end
		if free and slopeAt(sampler, x, z) <= config.MAX_SLOPE then
			local spot = { x = x, z = z, radius = radius }
			table.insert(own, spot)
			table.insert(all, spot)
			return Vector3.new(x, sampler.height(x, z), z)
		end
	end
	return nil
end

-- A camp of elites for groups (Config/Camps): its enemy spawns, the chest's anchor in front, and
-- tents around a campfire behind.
local function buildCamp(parent: Instance, center: Vector3, sampler: any, index: number)
	local camp = folderIn(parent, `Camp{index}`)
	local function ground(dx: number, dz: number): CFrame
		local x, z = center.X + dx, center.Z + dz
		return CFrame.new(x, sampler.height(x, z) - 0.2, z)
	end
	for groupIndex, group in CampsConfig.TEST_ENEMIES do
		local part =
			marker(camp, "EnemySpawn", ground((groupIndex - 2) * 8, 0).Position + Vector3.new(0, 1, 0), Vector3.one)
		part:SetAttribute("Enemy", group.kind)
		part:SetAttribute("Count", group.count)
		part:SetAttribute("Elite", group.elite)
		part:SetAttribute("Respawns", false)
		part:SetAttribute("Radius", 4)
		CollectionService:AddTag(part, Enemies.SPAWN_TAG)
	end
	marker(camp, "ChestAnchor", ground(0, 10).Position + Vector3.new(0, 1, 0), Vector3.one)
	local fire = ground(0, -12)
	Props.campfire(camp, fire)
	for _, spot in { { -18, -22 }, { 18, -22 }, { 0, -32 } } do
		local base = ground(spot[1], spot[2])
		Props.tent(camp, CFrame.lookAt(base.Position, Vector3.new(fire.X, base.Y, fire.Z)))
	end
	Props.crate(camp, ground(-10, -30), 2.4)
	Props.barrel(camp, ground(10, -30))
	CollectionService:AddTag(camp, CAMP_TAG)
end

-- Camps, dungeon entrances and groups of enemies. Returns the gameplay spots, for nature to keep
-- clear, and how many of each it placed.
local function buildGameplay(
	parent: Instance,
	config: any,
	sampler: any,
	random: Random
): ({ Spot }, { [string]: number })
	local all: { Spot } = {}
	local counts = { camps = 0, entrances = 0, groupEntrances = 0, enemyGroups = 0 }

	local camps = folderIn(parent, "Camps")
	local campSpots: { Spot } = {}
	for kind, count in config.CAMPS do
		local zone = zoneOfKind(config, kind)
		for _ = 1, if zone then count else 0 do
			local spot = findSpot(config, sampler, random, zone, 40, campSpots, config.CAMP_SPACING, all, 40)
			if spot then
				counts.camps += 1
				buildCamp(camps, spot, sampler, counts.camps)
			end
		end
	end

	local dungeons = folderIn(parent, "DungeonEntrances")
	local entranceSpots: { Spot } = {}
	local function entrance(zone: any, tag: string, name: string): boolean
		local spot = findSpot(config, sampler, random, zone, 12, entranceSpots, config.ENTRANCE_SPACING, all, 60)
		if not spot then
			return false
		end
		local part = marker(dungeons, name, spot + Vector3.new(0, 0.5, 0), Vector3.new(2, 1, 2))
		CollectionService:AddTag(part, tag)
		return true
	end
	for kind, count in config.DUNGEON_ENTRANCES do
		local zone = zoneOfKind(config, kind)
		for _ = 1, if zone then count else 0 do
			if entrance(zone, ENTRANCE_TAG, "DungeonEntrance") then
				counts.entrances += 1
			end
		end
	end
	local groupZone = zoneOfKind(config, config.GROUP_DUNGEON_ZONE)
	if groupZone and entrance(groupZone, GROUP_ENTRANCE_TAG, "GroupDungeonEntrance") then
		counts.groupEntrances += 1
	end

	local enemies = folderIn(parent, "EnemySpawns")
	local groupSpots: { Spot } = {}
	for _, zone in config.ZONES do
		local spec = config.ENEMIES[zone.kind]
		for _ = 1, if spec then spec.groups else 0 do
			local spot = findSpot(config, sampler, random, zone, 10, groupSpots, config.ENEMY_SPACING, all, 20)
			if spot then
				local mix = spec.mixes[random:NextInteger(1, #spec.mixes)]
				local part = marker(enemies, "EnemySpawn", spot + Vector3.new(0, 1, 0), Vector3.one)
				part:SetAttribute("Enemy", mix[1])
				part:SetAttribute("Count", mix[2])
				part:SetAttribute("Elite", random:NextNumber() < spec.eliteChance)
				part:SetAttribute("Radius", config.ENEMY_RADIUS)
				CollectionService:AddTag(part, Enemies.SPAWN_TAG)
				counts.enemyGroups += 1
			end
		end
	end
	return all, counts
end

-- Nature in every zone, from Config/World.NATURE, kept clear of the paths, the city, the spawn and
-- the gameplay spots, and apart from each other.
local function buildNature(parent: Instance, config: any, sampler: any, random: Random, gameplay: { Spot }): number
	local folder = folderIn(parent, "Nature")
	local T = config.TERRAIN
	local city, spawn = config.CITY, config.SPAWN
	local cells: { [string]: { Spot } } = {}
	local lights = 0
	local placedCount = 0

	local function cellKey(x: number, z: number): string
		return `{x // NATURE_CELL},{z // NATURE_CELL}`
	end
	local function crowded(x: number, z: number, radius: number): boolean
		local reach = math.ceil((radius + 24) / NATURE_CELL)
		local cx, cz = x // NATURE_CELL, z // NATURE_CELL
		for dx = -reach, reach do
			for dz = -reach, reach do
				local list = cells[`{cx + dx},{cz + dz}`]
				if list then
					for _, other in list do
						if (x - other.x) ^ 2 + (z - other.z) ^ 2 < (radius + other.radius + 4) ^ 2 then
							return true
						end
					end
				end
			end
		end
		return false
	end

	for _, zone in config.ZONES do
		local nature = config.NATURE[zone.kind]
		if nature then
			local area = folderIn(folder, zone.name)
			local minX, minZ, maxX, maxZ = zoneBox(zone)
			local owned = 0
			for x = minX, maxX, AREA_CELL do
				for z = minZ, maxZ, AREA_CELL do
					if sampler.owner(x, z) == zone then
						owned += AREA_CELL * AREA_CELL
					end
				end
			end
			local function count(density: number?): number
				return if density then math.floor(owned / 10000 * density + 0.5) else 0
			end
			-- A free spot (a frame on the ground, turned at random) for an item of `radius`.
			local function spot(radius: number, maxSlope: number, nearPath: { number }?): CFrame?
				for _ = 1, SPOT_TRIES do
					local x, z = random:NextNumber(minX, maxX), random:NextNumber(minZ, maxZ)
					local toPath = sampler.pathDistance(x, z)
					local free = sampler.owner(x, z) == zone
						and sampler.inside(x, z) > radius + 30
						and toPath > T.PATH_WIDTH + radius + 4
						and (nearPath == nil or (toPath >= nearPath[1] and toPath <= nearPath[2]))
						and (x - city.x) ^ 2 + (z - city.z) ^ 2 > (city.flat + radius) ^ 2
						and (x - spawn.x) ^ 2 + (z - spawn.z) ^ 2 > (spawn.flat + 20 + radius) ^ 2
						and not crowded(x, z, radius)
					if free then
						for _, other in gameplay do
							if
								(x - other.x) ^ 2 + (z - other.z) ^ 2
								< (other.radius + radius + config.CLEAR_POINT) ^ 2
							then
								free = false
								break
							end
						end
					end
					if free and slopeAt(sampler, x, z) <= maxSlope then
						local item = { x = x, z = z, radius = radius }
						local key = cellKey(x, z)
						cells[key] = cells[key] or {}
						table.insert(cells[key], item)
						placedCount += 1
						return CFrame.new(x, sampler.height(x, z) - 0.3, z)
							* CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0)
					end
				end
				return nil
			end

			for _ = 1, nature.ruins or 0 do
				local frame = spot(10, 15, { 40, 160 })
				if frame then
					Props.ruin(area, frame, random)
				end
			end
			for _ = 1, nature.towers or 0 do
				local frame = spot(7, 15, { 30, 90 })
				if frame then
					Props.watchtower(area, frame)
				end
			end
			for _ = 1, count(nature.spires) do
				local frame = spot(7, 45)
				if frame then
					Props.spire(area, frame, random)
				end
			end
			for _ = 1, count(nature.trees) do
				local height = random:NextNumber(14, 24)
				local crown = random:NextNumber(12, 20)
				local frame = spot(crown / 2, 28)
				if frame then
					Props.tree(area, frame, height, crown, random, random:NextNumber() < (nature.blossom or 0))
				end
			end
			for _ = 1, count(nature.deadTrees) do
				local frame = spot(4, 32)
				if frame then
					Props.deadTree(area, frame, random:NextNumber(10, 16), random)
				end
			end
			for _ = 1, count(nature.crystals) do
				local size = random:NextNumber(4, 8)
				local frame = spot(size * 0.6, 40)
				if frame then
					local glow = lights < SceneryConfig.MAX_CRYSTAL_LIGHTS
					if glow then
						lights += 1
					end
					local color = SceneryConfig.CRYSTALS[zone.kind] or SceneryConfig.CRYSTALS.Yellow
					Props.crystals(area, frame, size, random, color, glow)
				end
			end
			for _ = 1, count(nature.rocks) do
				local size = random:NextNumber(3, if zone.kind == "Red" then 12 else 9)
				local frame = spot(size * 0.7, 40)
				if frame then
					local color = if zone.kind == "Red" then SceneryConfig.PALETTE.darkRock else nil
					Props.rock(area, frame, size, random, color)
				end
			end
			for _ = 1, count(nature.bushes) do
				local size = random:NextNumber(3, 6)
				local frame = spot(size / 2, 30)
				if frame then
					Props.bush(area, frame, size, random)
				end
			end
			task.wait()
		end
	end
	return placedCount
end

-- Streaming and animated grass suit a big terrain map; both are set if Studio lets the command bar
-- set them.
local function tuneWorkspace()
	if not pcall(function()
		Workspace.StreamingEnabled = true
	end) then
		log("could not turn on Workspace.StreamingEnabled: turn it on in Workspace's properties")
	end
	pcall(function()
		(Workspace.Terrain :: any).Decoration = true
	end)
end

-- Builds the world. `config` is Config/World and `WorldShape` the shape module, both fresh copies
-- (WorldTools.Run).
function Generator.generate(config: any, WorldShape: any)
	assert(not RunService:IsRunning(), "Run the world generator in Edit mode, not during Play.")
	local started = os.clock()
	local recording = pcall(function()
		ChangeHistoryService:SetEnabled(false)
	end)

	local ok, problem = pcall(function()
		local minX, minZ, maxX, maxZ = WorldShape.bounds(config)
		local margin = config.TERRAIN.MARGIN
		local sampler = WorldShape.sampler(config, minX - margin, minZ - margin, maxX + margin, maxZ + margin)
		clearOld(sampler)
		local chunks = writeTerrain(config, WorldShape)

		local world = Instance.new("Folder")
		world.Name = "StardawnWorld"
		CollectionService:AddTag(world, GENERATED_TAG)
		local regions = buildRegions(world, config)
		placeSpawn(config, sampler)
		local returns = buildReturnPoints(world, config, sampler)
		local random = Random.new(config.SEED)
		local gameplay, counts = buildGameplay(world, config, sampler, random)
		log("placing nature")
		local nature = buildNature(world, config, sampler, random, gameplay)
		world.Parent = Workspace
		tuneWorkspace()

		log(
			`done in {math.floor(os.clock() - started)} s: {chunks} terrain chunks, {regions} zone regions, `
				.. `{returns} return points, {counts.enemyGroups} enemy groups, {counts.camps} camps, `
				.. `{counts.entrances} dungeon entrances, {counts.groupEntrances} group dungeon entrance, `
				.. `{nature} nature items`
		)
		log("save the place now (File > Save), then press Play")
	end)

	if recording then
		pcall(function()
			ChangeHistoryService:SetEnabled(true)
			ChangeHistoryService:ResetWaypoints()
		end)
	end
	if not ok then
		error(problem, 0)
	end
end

return table.freeze(Generator)
