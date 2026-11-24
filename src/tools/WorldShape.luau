--!strict
--[[
	WorldShape.luau
	The shape of the world of Stardawn (US-055), as pure functions of a point (x, z) for the
	generator. They answer four questions:
	- which zone owns the point: the smallest circle holding it, as the zone regions do at runtime;
	- how far the point is from a path;
	- the ground height. It adds the wide swells, the zone's hills and ridges blended across
	  borders, the beaten ground of the paths, the mountains beyond the zones, and the flat
	  grounds of the city and the spawn;
	- the ground material: the zone's, the paths', rock on steep slopes and snow on the peaks.
	Config/World comes in as an argument, so a fresh copy counts on every run. A sampler covers one
	area and looks only at the circles and path pieces that can reach it, which keeps the generation
	fast.
]]

export type Sampler = {
	owner: (x: number, z: number) -> any?,
	inside: (x: number, z: number) -> number,
	pathDistance: (x: number, z: number) -> number,
	height: (x: number, z: number) -> number,
	material: (x: number, z: number, height: number, slope: number) -> Enum.Material,
}

type Circle = { zone: any, rank: number, x: number, z: number, radius: number }
type Segment = { ax: number, az: number, bx: number, bz: number }

-- math.noise stays mostly within ±0.7; this brings it near ±1.
local NOISE_GAIN = 1.4

local WorldShape = {}

local function smoothstep(edge0: number, edge1: number, x: number): number
	local t = math.clamp((x - edge0) / (edge1 - edge0), 0, 1)
	return t * t * (3 - 2 * t)
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- Fractal noise: `octaves` layers of math.noise, each twice as fine and half as strong.
local function fbm(x: number, z: number, scale: number, octaves: number, seed: number): number
	local total, amplitude, frequency, norm = 0, 1, 1 / scale, 0
	for octave = 1, octaves do
		total += math.noise(x * frequency, z * frequency, seed + octave * 7.13) * amplitude
		norm += amplitude
		amplitude *= 0.5
		frequency *= 2
	end
	return total / norm * NOISE_GAIN
end

local function distanceToSegment(x: number, z: number, segment: Segment): number
	local dx, dz = segment.bx - segment.ax, segment.bz - segment.az
	local lengthSquared = dx * dx + dz * dz
	local t = if lengthSquared > 0
		then math.clamp(((x - segment.ax) * dx + (z - segment.az) * dz) / lengthSquared, 0, 1)
		else 0
	local px, pz = segment.ax + t * dx - x, segment.az + t * dz - z
	return math.sqrt(px * px + pz * pz)
end

-- How far a point can be from the area and still matter to it (blends, mountains, wandering borders).
local function reachOf(config: any): number
	local T = config.TERRAIN
	return math.max(T.BLEND, T.EDGE_INSIDE + T.EDGE_RISE) + T.BORDER_NOISE + T.PATH_WIDTH + T.PATH_FADE
end

-- A sampler for the area from (minX, minZ) to (maxX, maxZ).
function WorldShape.sampler(config: any, minX: number, minZ: number, maxX: number, maxZ: number): Sampler
	local T = config.TERRAIN
	local seed = T.SEED
	local reach = reachOf(config)

	-- The circles that can reach the area, with the rank of their zone (0 = outermost).
	local circles: { Circle } = {}
	for rank, zone in config.ZONES do
		for _, circle in zone.circles do
			local x, z, radius = circle[1], circle[2], circle[3]
			local nearX = math.clamp(x, minX, maxX)
			local nearZ = math.clamp(z, minZ, maxZ)
			local gap = math.sqrt((x - nearX) ^ 2 + (z - nearZ) ^ 2) - radius
			if gap < reach then
				table.insert(circles, { zone = zone, rank = rank - 1, x = x, z = z, radius = radius })
			end
		end
	end

	-- The path pieces that can reach the area.
	local segments: { Segment } = {}
	local pathReach = T.PATH_WIDTH + T.PATH_FADE + reach
	for _, path in config.PATHS do
		for index = 1, #path - 1 do
			local a, b = path[index], path[index + 1]
			local segment = { ax = a[1], az = a[2], bx = b[1], bz = b[2] }
			local left, right = math.min(a[1], b[1]) - pathReach, math.max(a[1], b[1]) + pathReach
			local top, bottom = math.min(a[2], b[2]) - pathReach, math.max(a[2], b[2]) + pathReach
			if right >= minX and left <= maxX and bottom >= minZ and top <= maxZ then
				table.insert(segments, segment)
			end
		end
	end

	local zoneCount = #config.ZONES
	-- Reused by every relief() call: how deep the point is inside each zone.
	local depths = table.create(zoneCount, -math.huge)

	local function owner(x: number, z: number): any?
		local best: any? = nil
		local bestRadius = math.huge
		for _, circle in circles do
			local dx, dz = x - circle.x, z - circle.z
			if dx * dx + dz * dz <= circle.radius * circle.radius and circle.radius < bestRadius then
				best = circle.zone
				bestRadius = circle.radius
			end
		end
		return best
	end

	-- How deep the point is inside the map (studs; negative outside every zone).
	local function inside(x: number, z: number): number
		local best = -math.huge
		for _, circle in circles do
			local depth = circle.radius - math.sqrt((x - circle.x) ^ 2 + (z - circle.z) ^ 2)
			if depth > best then
				best = depth
			end
		end
		return best
	end

	local function pathDistance(x: number, z: number): number
		local best = math.huge
		for _, segment in segments do
			local distance = distanceToSegment(x, z, segment)
			if distance < best then
				best = distance
			end
		end
		return best
	end

	-- The zones' relief here: the outermost zone's, with each inner zone laid over it near and
	-- inside its circles.
	local function relief(x: number, z: number): (number, number, number, number)
		for index = 1, zoneCount do
			depths[index] = -math.huge
		end
		for _, circle in circles do
			local depth = circle.radius - math.sqrt((x - circle.x) ^ 2 + (z - circle.z) ^ 2)
			local index = circle.rank + 1
			if depth > depths[index] then
				depths[index] = depth
			end
		end
		local base = config.RELIEF[config.ZONES[1].kind]
		local hills, hillScale, ridges, ridgeScale = base.hills, base.hillScale, base.ridges, base.ridgeScale
		for index = 2, zoneCount do
			local weight = smoothstep(-T.BLEND / 2, T.BLEND / 2, depths[index])
			if weight > 0 then
				local over = config.RELIEF[config.ZONES[index].kind]
				hills = lerp(hills, over.hills, weight)
				hillScale = lerp(hillScale, over.hillScale, weight)
				ridges = lerp(ridges, over.ridges, weight)
				ridgeScale = lerp(ridgeScale, over.ridgeScale, weight)
			end
		end
		return hills, hillScale, ridges, ridgeScale
	end

	local city, spawn = config.CITY, config.SPAWN
	local spawnHeight = T.BASE_HEIGHT + fbm(spawn.x, spawn.z, T.SWELL_SCALE, 2, seed + 11) * T.SWELL_HEIGHT

	local function height(x: number, z: number): number
		local hills, hillScale, ridges, ridgeScale = relief(x, z)
		local swell = fbm(x, z, T.SWELL_SCALE, 2, seed + 11) * T.SWELL_HEIGHT
		local detail = if hills > 0.5 then fbm(x, z, hillScale, 3, seed + 21) * hills else 0
		local ridged = 0
		if ridges > 0.5 then
			local ridge = 1 - math.abs(fbm(x, z, ridgeScale, 2, seed + 31))
			ridged = math.clamp((ridge - 0.45) / 0.55, 0, 1) ^ 1.5 * ridges
		end
		local onPath = 1 - smoothstep(T.PATH_WIDTH, T.PATH_WIDTH + T.PATH_FADE, pathDistance(x, z))
		local ground = T.BASE_HEIGHT + swell + (detail + ridged) * (1 - onPath)

		local edge = smoothstep(T.EDGE_INSIDE, -T.EDGE_RISE, inside(x, z))
		if edge > 0 then
			local ridge = 1 - math.abs(fbm(x, z, T.EDGE_SCALE, 3, seed + 41))
			local peaks = math.clamp((ridge - 0.2) / 0.8, 0, 1) ^ 1.3
			ground += edge * (T.EDGE_HEIGHT * 0.55 + peaks * T.EDGE_PEAKS * 1.6)
		end

		local toCity = math.sqrt((x - city.x) ^ 2 + (z - city.z) ^ 2)
		ground = lerp(ground, city.height, 1 - smoothstep(city.flat, city.flat + city.blend, toCity))
		local toSpawn = math.sqrt((x - spawn.x) ^ 2 + (z - spawn.z) ^ 2)
		ground = lerp(ground, spawnHeight, 1 - smoothstep(spawn.flat, spawn.flat + spawn.blend, toSpawn))
		return ground
	end

	local function material(x: number, z: number, ground: number, slope: number): Enum.Material
		if ground >= T.SNOW_HEIGHT then
			return Enum.Material.Snow
		end
		-- The edge between two zones' grounds wanders, so it does not look like a circle.
		local wobble = fbm(x, z, 260, 2, seed + 51) * T.BORDER_NOISE
		local zone = owner(x + wobble, z - wobble)
		if not zone then
			return Enum.Material.Rock
		end
		local look = config.RELIEF[zone.kind]
		if pathDistance(x, z) < T.PATH_WIDTH then
			return look.path
		end
		if slope >= T.ROCK_SLOPE then
			return Enum.Material.Rock
		end
		if look.patches and fbm(x, z, 180, 2, seed + 61) > 0.2 then
			return look.patches
		end
		return look.material
	end

	return {
		owner = owner,
		inside = inside,
		pathDistance = pathDistance,
		height = height,
		material = material,
	}
end

-- The box holding every zone: min x, min z, max x, max z.
function WorldShape.bounds(config: any): (number, number, number, number)
	local minX, minZ, maxX, maxZ = math.huge, math.huge, -math.huge, -math.huge
	for _, zone in config.ZONES do
		for _, circle in zone.circles do
			minX = math.min(minX, circle[1] - circle[3])
			maxX = math.max(maxX, circle[1] + circle[3])
			minZ = math.min(minZ, circle[2] - circle[3])
			maxZ = math.max(maxZ, circle[2] + circle[3])
		end
	end
	return minX, minZ, maxX, maxZ
end

return table.freeze(WorldShape)
