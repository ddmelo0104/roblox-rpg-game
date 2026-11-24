--!strict
--[[
	SceneryBuilder.luau
	Builds the provisional scenery of the test layout (US-054) from Config/Scenery, in one folder
	tagged Scenery, unparented: the caller places it. It builds:
	- a ground of its own for each risky zone (the meadow is the baseplate, painted by the caller)
	  and a road from the spawn through every zone;
	- border markers where neither side is the city, which has its gates: two pillars with
	  crystals in the color of the zone ahead, and a sign over the road naming the zone on each
	  side. A risky zone also gets posts along the whole border;
	- a signpost by the spawn pointing to the city and the zones, with their distances;
	- tents and a campfire at each camp;
	- each zone's nature: Blue trees, some with pink blossom; Yellow hills, ruins and pink
	  crystals; Red stone spires, dead trees, red crystals and old watchtowers;
	- mountains around the play area (always streamed, so the horizon never has holes) and an
	  invisible wall just outside the zones.
	Nothing is placed on the road, in the city or near a gameplay point (Layout.avoid).
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SceneryConfig = require(ReplicatedStorage.Shared.Config.Scenery)
local ZonesConfig = require(ReplicatedStorage.Shared.Config.Zones)
local World = require(ReplicatedStorage.Shared.World)
local Build = require(script.Parent.Build)
local Props = require(script.Parent.Props)

export type ZoneSpec = { zone: string, tier: number, name: string, from: number, to: number }
export type Avoid = { position: Vector3, radius: number }
export type Layout = {
	-- The spawn's frame on the ground: the zones lie toward its -X, `from` to `to` studs away.
	origin: CFrame,
	-- Size of the zones across the road (studs).
	depth: number,
	-- The zones, in order from the spawn.
	zones: { ZoneSpec },
	-- Gameplay points to keep clear.
	avoid: { Avoid },
	-- The city's box (its walls and gates), kept clear.
	city: { cframe: CFrame, size: Vector3 }?,
	-- The center of each camp, for its tents and campfire.
	camps: { Vector3 },
}

type Placed = { position: Vector3, radius: number }

local S = SceneryConfig
local PALETTE = SceneryConfig.PALETTE
-- Meters in 1 stud, for the distances on the signpost (the design doc writes meters).
local METERS_PER_STUD = 0.28
-- Tries to find a free spot for one prop before giving up on it.
local SPOT_TRIES = 12

local SIGN_WOOD = { material = Enum.Material.WoodPlanks, color = Color3.fromRGB(96, 68, 48), name = "Sign" }
local SIGN_TEXT = { color = Color3.fromRGB(255, 238, 205), pixelsPerStud = 50 }

local SceneryBuilder = {}

-- A frame on the ground, `left` studs from the spawn along the zones and `z` studs across.
local function at(layout: Layout, left: number, z: number): CFrame
	return layout.origin * CFrame.new(-left, 0, z)
end

local function flatDistance(a: Vector3, b: Vector3): number
	return Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude
end

-- Whether a prop of `radius` fits at `position`: off the road, out of the city and away from
-- gameplay points and other props.
local function isClear(layout: Layout, placed: { Placed }, position: Vector3, radius: number): boolean
	if math.abs(layout.origin:PointToObjectSpace(position).Z) < S.CLEAR_ROAD + radius then
		return false
	end
	local city = layout.city
	if city then
		local inCity = city.cframe:PointToObjectSpace(position)
		local margin = S.CLEAR_CITY + radius
		if math.abs(inCity.X) < city.size.X / 2 + margin and math.abs(inCity.Z) < city.size.Z / 2 + margin then
			return false
		end
	end
	for _, point in layout.avoid do
		if flatDistance(point.position, position) < point.radius + radius then
			return false
		end
	end
	for _, other in placed do
		if flatDistance(other.position, position) < other.radius + radius + S.PROP_SPACING then
			return false
		end
	end
	return true
end

-- A free spot in `zone` for a prop of `radius`, turned at random, or nil. With `band`, the spot is
-- that many studs from the road (on either side).
local function spotIn(
	layout: Layout,
	placed: { Placed },
	random: Random,
	zone: ZoneSpec,
	radius: number,
	band: { number }?
): CFrame?
	local minLeft = zone.from + S.EDGE_MARGIN + radius
	local maxLeft = zone.to - S.EDGE_MARGIN - radius
	local half = layout.depth / 2 - S.EDGE_MARGIN - radius
	if minLeft >= maxLeft or half <= 0 then
		return nil
	end
	for _ = 1, SPOT_TRIES do
		local left = random:NextNumber(minLeft, maxLeft)
		local z = if band
			then (if random:NextNumber() < 0.5 then -1 else 1) * random:NextNumber(band[1], band[2])
			else random:NextNumber(-half, half)
		local frame = at(layout, left, z) * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0)
		if isClear(layout, placed, frame.Position, radius) then
			table.insert(placed, { position = frame.Position, radius = radius })
			return frame
		end
	end
	return nil
end

-- The text a sign shows about a zone (game text).
local function zoneText(zone: ZoneSpec): string
	local rules = ZonesConfig.KINDS[zone.zone]
	if not rules then
		return zone.name
	end
	return `{zone.name}\n{rules.name} · T{zone.tier}\n{rules.summary}`
end

local function buildGround(folder: Folder, layout: Layout)
	for _, zone in layout.zones do
		local ground = S.GROUNDS[zone.zone]
		if ground then
			Build.block(
				folder,
				Vector3.new(zone.to - zone.from, 0.24, layout.depth),
				at(layout, (zone.from + zone.to) / 2, 0),
				{ material = ground.material, color = ground.color, name = `Ground ({zone.name})` }
			)
		end
	end
end

local function buildRoad(folder: Folder, layout: Layout)
	for _, zone in layout.zones do
		local look = S.ROADS[zone.zone]
		local from = math.max(zone.from, S.ROAD_START)
		local length = zone.to - from
		if look and length > 0 then
			Build.block(
				folder,
				Vector3.new(length, 0.3, S.ROAD_WIDTH),
				at(layout, from + length / 2, 0) * CFrame.new(0, 0.07, 0),
				{ material = look.material, color = look.color, name = `Road ({zone.name})` }
			)
		end
	end
end

local function buildBorders(folder: Folder, layout: Layout)
	local zones = layout.zones
	for index = 1, #zones - 1 do
		local before, after = zones[index], zones[index + 1]
		local rules = ZonesConfig.KINDS[after.zone]
		if before.zone ~= "City" and after.zone ~= "City" and rules then
			local left = before.to
			local pillar = { material = Enum.Material.Slate, color = PALETTE.darkRock, name = "BorderPillar" }
			local crystal = {
				material = Enum.Material.Glass,
				color = rules.color,
				transparency = 0.1,
				collide = false,
				shadow = false,
				name = "BorderCrystal",
			}
			for _, side in { -1, 1 } do
				local base = at(layout, left, side * (S.ROAD_WIDTH / 2 + 2.5))
				Build.block(folder, Vector3.new(3, 12, 3), base * CFrame.new(0, 6, 0), pillar)
				local top = Build.block(
					folder,
					Vector3.new(1.8, 3.2, 1.8),
					base * CFrame.new(0, 13.6, 0) * CFrame.Angles(0, math.rad(45), 0),
					crystal
				)
				Build.light(top, rules.color, 14, 1)
			end
			Build.block(
				folder,
				Vector3.new(0.8, 0.8, S.ROAD_WIDTH + 8),
				at(layout, left, 0) * CFrame.new(0, 11, 0),
				{ material = Enum.Material.Wood, color = PALETTE.deadWood, name = "BorderBeam" }
			)
			-- The front of the sign faces whoever comes from the spawn's side.
			local board = Build.block(
				folder,
				Vector3.new(S.ROAD_WIDTH + 2, 3.4, 0.3),
				at(layout, left, 0) * CFrame.new(0, 8.6, 0) * CFrame.Angles(0, math.rad(-90), 0),
				SIGN_WOOD
			)
			Build.text(board, Enum.NormalId.Front, zoneText(after), SIGN_TEXT)
			Build.text(board, Enum.NormalId.Back, zoneText(before), SIGN_TEXT)

			if rules.risk then
				local half = layout.depth / 2 - 10
				local z = -half
				while z <= half do
					if math.abs(z) > S.ROAD_WIDTH / 2 + 8 then
						local base = at(layout, left, z)
						Build.block(folder, Vector3.new(1.6, 5, 1.6), base * CFrame.new(0, 2.5, 0), pillar)
						Build.block(
							folder,
							Vector3.new(1.1, 2.2, 1.1),
							base * CFrame.new(0, 5.9, 0) * CFrame.Angles(0, math.rad(45), 0),
							crystal
						)
					end
					z += S.BORDER_POST_SPACING
				end
			end
		end
	end
end

-- A signpost by the spawn: the way to the city and to each zone, with the distance.
local function buildSignpost(folder: Folder, layout: Layout)
	local spot = S.SIGNPOST
	local base = at(layout, spot.left, spot.z)
	Build.cylinder(
		folder,
		8,
		0.6,
		base * CFrame.new(0, 4, 0),
		{ material = Enum.Material.Wood, color = PALETTE.trunk, name = "Signpost" }
	)
	local lines = {}
	for _, zone in layout.zones do
		if zone.from > spot.left then
			local rules = ZonesConfig.KINDS[zone.zone]
			local meters = math.floor((zone.from - spot.left) * METERS_PER_STUD + 0.5)
			table.insert(lines, `↑ {zone.name} ({if rules then rules.name else zone.zone}) · {meters} m`)
		end
	end
	local board = Build.block(
		folder,
		Vector3.new(8, 4, 0.3),
		base * CFrame.new(0, 6, 0) * CFrame.Angles(0, math.rad(-90), 0),
		SIGN_WOOD
	)
	Build.text(board, Enum.NormalId.Front, table.concat(lines, "\n"), SIGN_TEXT)
end

-- Tents around a campfire, behind each camp (away from its chest).
local function buildCamps(folder: Folder, layout: Layout)
	for index, center in layout.camps do
		local camp = Build.folder(folder, `Camp{index}`)
		local frame = CFrame.new(center.X, layout.origin.Y, center.Z) * layout.origin.Rotation
		local fire = frame * CFrame.new(0, 0, -12)
		Props.campfire(camp, fire)
		for _, spot in { Vector3.new(-18, 0, -22), Vector3.new(18, 0, -22), Vector3.new(0, 0, -32) } do
			local position = (frame * CFrame.new(spot)).Position
			local target = Vector3.new(fire.Position.X, position.Y, fire.Position.Z)
			Props.tent(camp, CFrame.lookAt(position, target))
		end
		Props.crate(camp, frame * CFrame.new(-10, 0, -30), 2.4)
		Props.barrel(camp, frame * CFrame.new(10, 0, -30))
	end
end

-- Each zone's nature, biggest pieces first so they find room.
local function buildNature(folder: Folder, layout: Layout, placed: { Placed }, random: Random)
	local lights = 0
	for _, zone in layout.zones do
		local nature = S.NATURE[zone.zone]
		if nature then
			local area = Build.folder(folder, zone.name)
			local function count(density: number?): number
				if not density then
					return 0
				end
				return math.floor((zone.to - zone.from) * layout.depth / 10000 * density + 0.5)
			end
			local function spot(radius: number, band: { number }?): CFrame?
				return spotIn(layout, placed, random, zone, radius, band)
			end

			local ground = S.GROUNDS[zone.zone] or S.MEADOW
			for _ = 1, nature.hills or 0 do
				-- A ball sunk deep in the ground: a gentle hill that can be walked over.
				local radius = random:NextNumber(46, 64)
				local frame = spot(radius * 0.62)
				if frame then
					Build.ball(
						area,
						radius * 2,
						frame * CFrame.new(0, -radius * 0.8, 0),
						{ material = Enum.Material.Grass, color = ground.color, name = "Hill" }
					)
				end
			end
			for _ = 1, nature.ruins or 0 do
				local frame = spot(10, { 24, 70 })
				if frame then
					Props.ruin(area, frame, random)
				end
			end
			for _ = 1, nature.towers or 0 do
				local frame = spot(7, { 22, 40 })
				if frame then
					Props.watchtower(area, frame)
				end
			end
			for _ = 1, count(nature.spires) do
				local frame = spot(7)
				if frame then
					Props.spire(area, frame, random)
				end
			end
			for _ = 1, count(nature.trees) do
				local height = random:NextNumber(14, 24)
				local crown = random:NextNumber(12, 20)
				local frame = spot(crown / 2)
				if frame then
					Props.tree(area, frame, height, crown, random, random:NextNumber() < (nature.blossom or 0))
				end
			end
			for _ = 1, count(nature.deadTrees) do
				local frame = spot(4)
				if frame then
					Props.deadTree(area, frame, random:NextNumber(10, 16), random)
				end
			end
			for _ = 1, count(nature.crystals) do
				local size = random:NextNumber(4, 8)
				local frame = spot(size * 0.6)
				if frame then
					local glow = lights < S.MAX_CRYSTAL_LIGHTS
					if glow then
						lights += 1
					end
					Props.crystals(area, frame, size, random, S.CRYSTALS[zone.zone] or Color3.new(1, 1, 1), glow)
				end
			end
			for _ = 1, count(nature.rocks) do
				local size = random:NextNumber(3, if zone.zone == "Red" then 12 else 9)
				local frame = spot(size * 0.7)
				if frame then
					Props.rock(area, frame, size, random, if zone.zone == "Red" then PALETTE.darkRock else nil)
				end
			end
			for _ = 1, count(nature.bushes) do
				local size = random:NextNumber(3, 6)
				local frame = spot(size / 2)
				if frame then
					Props.bush(area, frame, size, random)
				end
			end
		end
	end
end

-- A mountain: big tilted blocks of rock, snow on the tallest and, sometimes, pink crystals at its foot.
local function mountain(parent: Instance, base: CFrame, size: number, random: Random)
	local function rock(): Build.Style
		return {
			material = if random:NextNumber() < 0.5 then Enum.Material.Rock else Enum.Material.Slate,
			color = PALETTE.mountain:Lerp(Color3.new(0, 0, 0), random:NextNumber(0, 0.25)),
			name = "Mountain",
		}
	end
	local main = base
		* CFrame.new(0, size * 0.12, 0)
		* CFrame.Angles(
			math.rad(random:NextNumber(-25, 25)),
			math.rad(random:NextNumber(0, 360)),
			math.rad(random:NextNumber(-25, 25))
		)
	Build.block(parent, Vector3.new(size, size * 0.9, size), main, rock())
	if size > 120 then
		Build.block(
			parent,
			Vector3.new(size * 0.6, size * 0.12, size * 0.6),
			main * CFrame.new(0, size * 0.41, 0),
			{ material = Enum.Material.Snow, color = PALETTE.snow, name = "Snow" }
		)
	end
	for _ = 1, random:NextInteger(2, 3) do
		local side = size * random:NextNumber(0.45, 0.7)
		local angle = random:NextNumber(0, math.pi * 2)
		Build.block(
			parent,
			Vector3.new(side, side * 0.9, side),
			base
				* CFrame.new(math.cos(angle) * size * 0.4, side * 0.05, math.sin(angle) * size * 0.4)
				* CFrame.Angles(
					math.rad(random:NextNumber(-25, 25)),
					math.rad(random:NextNumber(0, 360)),
					math.rad(random:NextNumber(-25, 25))
				),
			rock()
		)
	end
end

local function buildMountains(parent: Instance, layout: Layout, random: Random)
	local first, last = layout.zones[1], layout.zones[#layout.zones]
	local half = layout.depth / 2
	local distance = S.MOUNTAIN_DISTANCE
	local function size(): number
		return random:NextNumber(S.MOUNTAIN_MIN_SIZE, S.MOUNTAIN_MAX_SIZE)
	end
	local function crystalsToward(base: CFrame, z: number)
		if random:NextNumber() < 0.25 then
			local toward = base * CFrame.new(0, 0, if z > 0 then -size() * 0.45 else size() * 0.45)
			Props.crystals(parent, toward, random:NextNumber(10, 18), random, S.CRYSTALS.Yellow, false)
		end
	end
	-- Along both long sides of the zones.
	local left = first.from - distance
	while left <= last.to + distance do
		for _, side in { -1, 1 } do
			local z = side * (half + distance + random:NextNumber(0, 40))
			local base = at(layout, left + random:NextNumber(-20, 20), z)
			mountain(parent, base, size(), random)
			crystalsToward(base, z)
		end
		left += S.MOUNTAIN_SPACING
	end
	-- Across both ends.
	local z = -half
	while z <= half do
		mountain(parent, at(layout, first.from - distance - random:NextNumber(0, 40), z), size(), random)
		mountain(parent, at(layout, last.to + distance + random:NextNumber(0, 40), z), size(), random)
		z += S.MOUNTAIN_SPACING
	end
end

-- An invisible wall just outside the zones: it blocks walking, not sight, aim or the camera.
local function buildBoundary(folder: Folder, layout: Layout)
	local first, last = layout.zones[1], layout.zones[#layout.zones]
	local margin = S.BOUNDARY_MARGIN
	local half = layout.depth / 2 + margin
	local nearLeft, farLeft = first.from - margin, last.to + margin
	local height = S.BOUNDARY_HEIGHT
	local style = { transparency = 1, shadow = false, name = "Boundary" }
	local walls = {
		Build.block(
			folder,
			Vector3.new(farLeft - nearLeft + 20, height, 10),
			at(layout, (nearLeft + farLeft) / 2, -(half + 5)) * CFrame.new(0, height / 2, 0),
			style
		),
		Build.block(
			folder,
			Vector3.new(farLeft - nearLeft + 20, height, 10),
			at(layout, (nearLeft + farLeft) / 2, half + 5) * CFrame.new(0, height / 2, 0),
			style
		),
		Build.block(
			folder,
			Vector3.new(10, height, half * 2 + 20),
			at(layout, nearLeft - 5, 0) * CFrame.new(0, height / 2, 0),
			style
		),
		Build.block(
			folder,
			Vector3.new(10, height, half * 2 + 20),
			at(layout, farLeft + 5, 0) * CFrame.new(0, height / 2, 0),
			style
		),
	}
	for _, wall in walls do
		wall.CanQuery = false
	end
end

-- Builds the scenery for `layout`. Returns its folder, not yet in the world.
function SceneryBuilder.build(layout: Layout): Folder
	local random = Random.new(S.SEED)
	local folder = Build.folder(nil, "Scenery")
	local placed: { Placed } = {}
	buildGround(Build.folder(folder, "Ground"), layout)
	buildRoad(Build.folder(folder, "Road"), layout)
	buildBorders(Build.folder(folder, "Borders"), layout)
	buildSignpost(folder, layout)
	buildCamps(Build.folder(folder, "Camps"), layout)
	buildNature(Build.folder(folder, "Nature"), layout, placed, random)
	local mountains = Build.model(folder, "Mountains")
	mountains.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	buildMountains(mountains, layout, random)
	buildBoundary(Build.folder(folder, "Boundary"), layout)
	CollectionService:AddTag(folder, World.SCENERY_TAG)
	return folder
end

return table.freeze(SceneryBuilder)
