--!strict
--[[
	CityBuilder.luau
	Builds the provisional city of Stardawn (US-052) from Config/City, on a frame at the city's center
	on the ground, with its X along the road (+X toward the Blue zone). It builds:
	- a paved ground inside the walls, the main street through the two gates, the Star Square and the
	  market square;
	- walls with merlons, four corner towers, and two gates. Each gate has towers, banners, torches
	  and the eight-pointed star; "STARDAWN" is written outside and the zone beyond the gate inside;
	- the Star monument: the city's crest in pink crystal and gold, which turns on the clients
	  (tag Spin);
	- the bank (gold roof), the tavern, the smithy (forge with fire and smoke), the observatory, the
	  houses, the market stalls and the well;
	- street lamps, benches, blossom trees, barrels and crates.
	Everything goes into one model tagged CityModel, unparented: the caller places it. The center of
	the city stays free, on the main street: it is where players come back to the city (EP-009).
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CityConfig = require(ReplicatedStorage.Shared.Config.City)
local World = require(ReplicatedStorage.Shared.World)
local Build = require(script.Parent.Build)
local Props = require(script.Parent.Props)

type Building = CityConfig.Building

export type Options = {
	-- Game text inside each gate: the zone beyond it ("Campos de Stardawn · Zona Azul · T1").
	eastText: string?,
	westText: string?,
}

local C = CityConfig
local P = CityConfig.PALETTE

-- Game text written outside the gates.
local CITY_NAME = "STARDAWN"

-- Heights of the city's floors (top faces), so that no two floors fight over the same height.
local GROUND_TOP = 0.1
local STREET_TOP = 0.26
local MARKET_TOP = 0.3
local RING_TOP = 0.32
local SQUARE_TOP = 0.36

local STONE = { material = Enum.Material.Cobblestone, color = P.stone, name = "Wall" }
local DARK_STONE = { material = Enum.Material.Slate, color = P.darkStone, name = "Stone" }
local MARBLE = { material = Enum.Material.Marble, color = P.marble, name = "Marble" }
local GOLD = { material = Enum.Material.Metal, color = P.gold, name = "Gold" }
local TIMBER = { material = Enum.Material.Wood, color = P.timber, name = "Timber" }
local PLANKS = { material = Enum.Material.WoodPlanks, color = P.timber, name = "Planks" }
local ROOF = { material = Enum.Material.Slate, color = P.roof, name = "Roof" }
local BRICK = { material = Enum.Material.Brick, color = Color3.fromRGB(150, 96, 84), name = "Brick" }
local DOOR = { material = Enum.Material.WoodPlanks, color = Color3.fromRGB(70, 48, 34), name = "Door" }
local GLOW = {
	material = Enum.Material.Neon,
	color = P.windowGlow,
	transparency = 0.35,
	collide = false,
	shadow = false,
	name = "Window",
}

local CityBuilder = {}

-- A flat floor whose top face is at `top`.
local function floor(parent: Instance, size: Vector3, frame: CFrame, top: number, style: Build.Style)
	Build.block(parent, Vector3.new(size.X, 0.3, size.Z), frame * CFrame.new(0, top - 0.15, 0), style)
end

-- A round flat floor whose top face is at `top`.
local function disk(parent: Instance, diameter: number, frame: CFrame, top: number, style: Build.Style)
	Build.cylinder(parent, 0.3, diameter, frame * CFrame.new(0, top - 0.15, 0), style)
end

-- The pink-and-gold star of the crest at `cframe`, facing its Z: a gold outline behind a pink
-- crystal star, with a glowing gem in the middle. Returns the gem.
local function crest(parent: Instance, cframe: CFrame, size: number): Part
	Build.star(parent, cframe, size * 1.12, size * 0.11, GOLD)
	Build.star(parent, cframe, size, size * 0.2, {
		material = Enum.Material.Glass,
		color = P.crystal,
		transparency = 0.1,
		reflectance = 0.15,
		name = "Crystal",
	})
	return Build.ball(
		parent,
		size * 0.27,
		cframe,
		{ material = Enum.Material.Neon, color = P.gem, collide = false, shadow = false, name = "Gem" }
	)
end

local function buildGround(model: Model, city: CFrame)
	local folder = Build.folder(model, "Ground")
	local inner = Vector3.new(C.WALL_HALF_X * 2 - C.WALL_THICKNESS, 0, C.WALL_HALF_Z * 2 - C.WALL_THICKNESS)
	floor(folder, inner, city, GROUND_TOP, { material = Enum.Material.Ground, color = P.earth, name = "Ground" })

	local street = { material = Enum.Material.Cobblestone, color = P.cobble, name = "Street" }
	-- The main street runs through both gates and a little beyond.
	floor(folder, Vector3.new(C.WALL_HALF_X * 2 + 12, 0, C.STREET_WIDTH), city, STREET_TOP, street)
	local plaza = city * CFrame.new(C.PLAZA.x, 0, C.PLAZA.z)
	-- From the square to the bank, and from the main street to the market.
	floor(folder, Vector3.new(8, 0, 16), plaza * CFrame.new(0, 0, -C.PLAZA.radius - 6), STREET_TOP, street)
	local market = city * CFrame.new(C.MARKET.x, 0, C.MARKET.z)
	floor(
		folder,
		Vector3.new(16, 0, C.MARKET.depth / 2),
		city * CFrame.new(C.MARKET.x, 0, C.MARKET.z - C.MARKET.depth / 2),
		STREET_TOP,
		street
	)
	floor(folder, Vector3.new(C.MARKET.width, 0, C.MARKET.depth), market, MARKET_TOP, street)
	disk(
		folder,
		C.PLAZA.radius * 2 + 2,
		plaza,
		RING_TOP,
		{ material = Enum.Material.Metal, color = P.gold, name = "Ring" }
	)
	disk(
		folder,
		C.PLAZA.radius * 2,
		plaza,
		SQUARE_TOP,
		{ material = Enum.Material.Marble, color = P.marble, name = "Square" }
	)
end

-- A tower with merlons around its top and arrow slits on its faces.
local function tower(parent: Instance, base: CFrame, height: number)
	local size = C.TOWER_SIZE
	local merlon = C.MERLON_SIZE
	Build.block(parent, Vector3.new(size, height, size), base * CFrame.new(0, height / 2, 0), STONE)
	local edge = size / 2 - merlon / 2
	for _, offset in { { -1, -1 }, { 0, -1 }, { 1, -1 }, { 1, 0 }, { 1, 1 }, { 0, 1 }, { -1, 1 }, { -1, 0 } } do
		Build.block(
			parent,
			Vector3.new(merlon, merlon, merlon),
			base * CFrame.new(offset[1] * edge, height + merlon / 2, offset[2] * edge),
			STONE
		)
	end
	local slit = { material = Enum.Material.Slate, color = Color3.fromRGB(30, 28, 30), collide = false, shadow = false }
	for _, turn in { 0, 90, 180, 270 } do
		Build.block(
			parent,
			Vector3.new(0.8, 3, 0.2),
			base * CFrame.Angles(0, math.rad(turn), 0) * CFrame.new(0, height * 0.7, -size / 2 - 0.05),
			slit
		)
	end
end

-- A stretch of wall centered at (x, z) of the city, along X or along Z, with merlons on top.
local function wall(parent: Instance, city: CFrame, x: number, z: number, length: number, alongX: boolean)
	local thickness = C.WALL_THICKNESS
	local size = if alongX
		then Vector3.new(length, C.WALL_HEIGHT, thickness)
		else Vector3.new(thickness, C.WALL_HEIGHT, length)
	Build.block(parent, size, city * CFrame.new(x, C.WALL_HEIGHT / 2, z), STONE)
	local count = math.max(1, math.floor(length / C.MERLON_SPACING))
	local step = length / count
	local merlon = C.MERLON_SIZE
	local merlonSize = if alongX then Vector3.new(merlon, merlon, thickness) else Vector3.new(thickness, merlon, merlon)
	for index = 0, count - 1 do
		local offset = -length / 2 + step * (index + 0.5)
		local position = if alongX then Vector3.new(x + offset, 0, z) else Vector3.new(x, 0, z + offset)
		Build.block(parent, merlonSize, city * CFrame.new(position.X, C.WALL_HEIGHT + merlon / 2, position.Z), STONE)
	end
end

-- A gate on the east (side 1) or west (side -1) wall: two towers, the lintel over the opening with
-- the city's name outside and `innerText` inside, the crest on top, banners and torches.
local function gate(parent: Instance, city: CFrame, side: number, innerText: string?)
	local x = side * C.WALL_HALF_X
	local towerZ = C.GATE_WIDTH / 2 + C.TOWER_SIZE / 2
	for _, z in { -towerZ, towerZ } do
		tower(parent, city * CFrame.new(x, 0, z), C.GATE_TOWER_HEIGHT)
	end

	local lintelHeight = C.GATE_TOWER_HEIGHT - C.GATE_HEIGHT - 2
	local lintel = Build.block(
		parent,
		Vector3.new(C.WALL_THICKNESS + 2, lintelHeight, C.GATE_WIDTH),
		city * CFrame.new(x, C.GATE_HEIGHT + lintelHeight / 2, 0),
		MARBLE
	)
	local outer = if side > 0 then Enum.NormalId.Right else Enum.NormalId.Left
	local inner = if side > 0 then Enum.NormalId.Left else Enum.NormalId.Right
	Build.text(lintel, outer, CITY_NAME, { pixelsPerStud = 30 })
	if innerText then
		Build.text(lintel, inner, innerText, { pixelsPerStud = 40 })
	end

	-- The crest stands on the lintel, between the towers, facing out and in.
	local crestCenter = city * CFrame.new(x, C.GATE_TOWER_HEIGHT + 3, 0) * CFrame.Angles(0, math.rad(90), 0)
	Build.light(crest(parent, crestCenter, 5), P.crystal, 20, 1)

	-- Banners on the towers, outside and inside, and torches by the opening, outside.
	for _, z in { -towerZ, towerZ } do
		for _, facing in { side, -side } do
			local top = city
				* CFrame.new(x + facing * (C.TOWER_SIZE / 2 + 0.3), C.GATE_TOWER_HEIGHT - 4, z)
				* CFrame.Angles(0, math.rad(-90 * facing), 0)
			Props.banner(parent, top, 5, 11)
		end
		local zSide = if z > 0 then 1 else -1
		Props.torch(parent, city * CFrame.new(x + side * (C.TOWER_SIZE / 2 + 0.8), 11, zSide * (C.GATE_WIDTH / 2 + 2)))
	end
end

local function buildWalls(model: Model, city: CFrame, options: Options)
	local folder = Build.folder(model, "Walls")
	local hx, hz = C.WALL_HALF_X, C.WALL_HALF_Z
	local half = C.TOWER_SIZE / 2
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			tower(folder, city * CFrame.new(sx * hx, 0, sz * hz), C.CORNER_TOWER_HEIGHT)
		end
	end
	-- North and south walls, between the corner towers.
	for _, sz in { -1, 1 } do
		wall(folder, city, 0, sz * hz, hx * 2 - C.TOWER_SIZE, true)
	end
	-- East and west walls, between a corner tower and a gate tower.
	local gateEdge = C.GATE_WIDTH / 2 + C.TOWER_SIZE
	local length = hz - half - gateEdge
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			wall(folder, city, sx * hx, sz * (gateEdge + length / 2), length, false)
		end
	end
	gate(folder, city, 1, options.eastText)
	gate(folder, city, -1, options.westText)
end

-- The Star monument in the middle of the square: a pedestal and the crest, which turns.
local function buildMonument(model: Model, city: CFrame)
	local folder = Build.folder(model, "Monument")
	local plaza = city * CFrame.new(C.PLAZA.x, SQUARE_TOP, C.PLAZA.z)
	Build.cylinder(folder, 1.2, 13, plaza * CFrame.new(0, 0.6, 0), DARK_STONE)
	Build.cylinder(folder, 6, 7, plaza * CFrame.new(0, 4.2, 0), MARBLE)
	Build.cylinder(folder, 0.8, 8.5, plaza * CFrame.new(0, 7.6, 0), GOLD)

	local star = Build.model(folder, "Star")
	local gem = crest(star, plaza * CFrame.new(0, C.STAR_HEIGHT, 0), C.STAR_SIZE)
	Build.light(gem, P.crystal, 32, 1.6)
	star.PrimaryPart = gem
	star.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	star:SetAttribute(World.SPIN_SPEED, C.STAR_SPIN_SPEED)
	star:SetAttribute(World.BOB_HEIGHT, C.STAR_BOB_HEIGHT)
	CollectionService:AddTag(star, World.SPIN_TAG)
end

-- A house: stone base, plaster walls with timber, a pink slate roof, a door, glowing windows and,
-- sometimes, a chimney. The door is on the frame's -Z.
local function house(parent: Instance, place: CFrame, building: Building, random: Random)
	local w, d, h = building.width, building.depth, building.height
	Build.block(parent, Vector3.new(w + 0.8, 1, d + 0.8), place * CFrame.new(0, 0.5, 0), DARK_STONE)
	Build.block(
		parent,
		Vector3.new(w, h, d),
		place * CFrame.new(0, 1 + h / 2, 0),
		{ material = Enum.Material.Concrete, color = P.plaster, name = "Walls" }
	)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			Build.block(parent, Vector3.new(0.7, h, 0.7), place * CFrame.new(sx * w / 2, 1 + h / 2, sz * d / 2), TIMBER)
		end
	end
	for _, sz in { -1, 1 } do
		for _, height in { 1 + h * 0.55, 1 + h - 0.3 } do
			Build.block(
				parent,
				Vector3.new(w + 0.2, 0.6, 0.5),
				place * CFrame.new(0, height, sz * (d / 2 + 0.05)),
				TIMBER
			)
		end
	end
	local roofHeight = d * 0.45
	Build.gableRoof(parent, place * CFrame.new(0, 1 + h, 0), w + 2.4, d + 2.4, roofHeight, ROOF)
	Build.block(parent, Vector3.new(2.8, 5, 0.3), place * CFrame.new(0, 3.5, -d / 2 - 0.15), DOOR)
	for _, sx in { -1, 1 } do
		Build.block(parent, Vector3.new(2, 2.2, 0.2), place * CFrame.new(sx * w * 0.3, 4.2, -d / 2 - 0.1), GLOW)
		Build.block(
			parent,
			Vector3.new(2, 2.2, 0.2),
			place * CFrame.new(sx * w * 0.3, 1 + h * 0.78, -d / 2 - 0.1),
			GLOW
		)
		Build.block(parent, Vector3.new(0.2, 2.2, 2), place * CFrame.new(sx * (w / 2 + 0.1), 1 + h * 0.78, 0), GLOW)
	end
	if random:NextNumber() < 0.6 then
		local chimney = roofHeight + 3
		Build.block(
			parent,
			Vector3.new(2, chimney, 2),
			place * CFrame.new(w / 2 - 2.5, 1 + h + chimney / 2 - 1, d * 0.18),
			BRICK
		)
	end
end

-- The bank: a marble hall on a platform, with steps, six columns, the sign, the crest over the door
-- and a gold roof.
local function bank(parent: Instance, place: CFrame, building: Building)
	local w, d, h = building.width, building.depth, building.height
	local base = 1.2
	Build.block(parent, Vector3.new(w + 4, base, d + 6), place * CFrame.new(0, base / 2, -1), MARBLE)
	Build.block(parent, Vector3.new(w * 0.5, 0.8, 2), place * CFrame.new(0, 0.4, -(d / 2 + 5)), MARBLE)
	Build.block(parent, Vector3.new(w * 0.5, 0.4, 2), place * CFrame.new(0, 0.2, -(d / 2 + 7)), MARBLE)
	Build.block(parent, Vector3.new(w, h, d), place * CFrame.new(0, base + h / 2, 0), MARBLE)
	Build.block(parent, Vector3.new(w + 0.4, 0.8, d + 0.4), place * CFrame.new(0, base + h - 0.4, 0), GOLD)
	Build.block(parent, Vector3.new(w, 1, d), place * CFrame.new(0, base + h + 0.5, 0), MARBLE)
	local columnZ = -d / 2 - 2.5
	for index = 0, 5 do
		local x = -w / 2 + 2.5 + index * (w - 5) / 5
		Build.cylinder(parent, h - 1, 1.8, place * CFrame.new(x, base + (h - 1) / 2, columnZ), MARBLE)
	end
	local entablature = Build.block(parent, Vector3.new(w + 1, 2, 5), place * CFrame.new(0, base + h, columnZ), MARBLE)
	if building.sign then
		Build.text(entablature, Enum.NormalId.Front, building.sign, { pixelsPerStud = 30 })
	end
	Build.gableRoof(
		parent,
		place * CFrame.new(0, base + h + 1, -2.5),
		w + 1.6,
		d + 6.6,
		6,
		{ material = Enum.Material.Metal, color = Color3.fromRGB(210, 165, 75), name = "Roof" }
	)
	Build.block(parent, Vector3.new(6, 9, 0.4), place * CFrame.new(0, base + 4.5, -d / 2 - 0.2), DOOR)
	-- Tall windows between the outer columns, and the crest over the door.
	for _, sx in { -1, 1 } do
		Build.block(
			parent,
			Vector3.new(2.4, 6, 0.2),
			place * CFrame.new(sx * (w / 2 - 5.5), base + 6, -d / 2 - 0.1),
			GLOW
		)
	end
	crest(parent, place * CFrame.new(0, base + 12, -d / 2 - 0.6), 3.6)
end

-- The tavern: a big house with a hanging sign, barrels by the door and a lantern.
local function tavern(parent: Instance, place: CFrame, building: Building, random: Random)
	house(parent, place, building, random)
	local w, d, h = building.width, building.depth, building.height
	Build.block(parent, Vector3.new(0.4, 0.4, 3.4), place * CFrame.new(w / 2 - 1, 1 + h * 0.62, -d / 2 - 1.7), TIMBER)
	local board = Build.block(
		parent,
		Vector3.new(0.3, 2.6, 3.2),
		place * CFrame.new(w / 2 - 1, 1 + h * 0.62 - 1.6, -d / 2 - 1.9),
		{ material = Enum.Material.WoodPlanks, color = Color3.fromRGB(80, 54, 38), collide = false, name = "Sign" }
	)
	if building.sign then
		Build.text(board, Enum.NormalId.Left, building.sign, { pixelsPerStud = 50 })
		Build.text(board, Enum.NormalId.Right, building.sign, { pixelsPerStud = 50 })
	end
	for _, sx in { -1, 1 } do
		Props.barrel(parent, place * CFrame.new(sx * 3.4, 1, -d / 2 - 1.6))
	end
	local lantern = Build.block(
		parent,
		Vector3.new(1, 1.4, 1),
		place * CFrame.new(-2.4, 7.4, -d / 2 - 0.6),
		{ material = Enum.Material.Glass, color = P.windowGlow, transparency = 0.3, collide = false, name = "Lantern" }
	)
	Build.light(lantern, P.lampLight, 14, 1.2)
end

-- The smithy, where the repair will be: open in front, with the forge (fire and smoke), the anvil,
-- the quenching barrel and a rack of blades.
local function smithy(parent: Instance, place: CFrame, building: Building)
	local w, d, h = building.width, building.depth, building.height
	Build.block(
		parent,
		Vector3.new(w, 0.4, d),
		place * CFrame.new(0, 0.2, 0),
		{ material = Enum.Material.Cobblestone, color = P.darkStone, name = "Floor" }
	)
	Build.block(parent, Vector3.new(w, h, 1.2), place * CFrame.new(0, h / 2, d / 2 - 0.6), STONE)
	for _, sx in { -1, 1 } do
		Build.block(parent, Vector3.new(1.2, h, d), place * CFrame.new(sx * (w / 2 - 0.6), h / 2, 0), STONE)
	end
	local beam = Build.block(parent, Vector3.new(w, 1.4, 1), place * CFrame.new(0, h - 0.7, -d / 2 + 0.5), TIMBER)
	if building.sign then
		Build.text(beam, Enum.NormalId.Front, building.sign, { pixelsPerStud = 40 })
	end
	local roofHeight = d * 0.35
	Build.gableRoof(parent, place * CFrame.new(0, h, 0), w + 2, d + 2, roofHeight, ROOF)

	local forge = place * CFrame.new(-w / 2 + 3.6, 0, d / 2 - 3.4)
	Build.block(parent, Vector3.new(4.4, 3, 4), forge * CFrame.new(0, 1.5, 0), BRICK)
	local coals = Build.block(
		parent,
		Vector3.new(3, 0.3, 2.6),
		forge * CFrame.new(0, 3.1, 0),
		{ material = Enum.Material.Neon, color = Color3.fromRGB(255, 110, 40), collide = false, name = "Coals" }
	)
	Build.fire(coals, 3, 4, Color3.fromRGB(255, 150, 50), Color3.fromRGB(255, 60, 20))
	Build.light(coals, Color3.fromRGB(255, 130, 60), 22, 2.2)
	local chimneyHeight = h + roofHeight + 2
	local chimney = Build.block(
		parent,
		Vector3.new(2.6, chimneyHeight - 3, 2.6),
		forge * CFrame.new(0, 3 + (chimneyHeight - 3) / 2, 0.4),
		BRICK
	)
	local top = Build.block(
		parent,
		Vector3.new(2, 0.4, 2),
		forge * CFrame.new(0, chimneyHeight + 0.2, 0.4),
		{ material = Enum.Material.Slate, color = Color3.fromRGB(40, 36, 36), collide = false, name = "ChimneyTop" }
	)
	Build.smoke(top, Color3.fromRGB(90, 86, 86), 0.15, 3, 4)
	chimney.Name = "Chimney"

	local anvil = place * CFrame.new(1.5, 0.4, 0.5)
	Build.cylinder(parent, 2, 1.8, anvil * CFrame.new(0, 1, 0), TIMBER)
	local iron = { material = Enum.Material.Metal, color = Color3.fromRGB(46, 46, 50), name = "Anvil" }
	Build.block(parent, Vector3.new(2.6, 1, 1.2), anvil * CFrame.new(0, 2.5, 0), iron)
	Build.block(parent, Vector3.new(1, 0.6, 0.8), anvil * CFrame.new(1.7, 2.6, 0), iron)
	Props.barrel(parent, place * CFrame.new(w / 2 - 3.2, 0.4, d / 2 - 3.2))

	local rack = place * CFrame.new(w / 2 - 6, 0.4, d / 2 - 1.5)
	Build.block(parent, Vector3.new(5, 0.4, 0.4), rack * CFrame.new(0, 6.5, 0), TIMBER)
	for index = -1, 1 do
		Build.block(
			parent,
			Vector3.new(0.3, 4.2, 0.12),
			rack * CFrame.new(index * 1.5, 4.2, 0),
			{ material = Enum.Material.Metal, color = Color3.fromRGB(200, 204, 210), collide = false, name = "Blade" }
		)
		Build.block(
			parent,
			Vector3.new(1.2, 0.3, 0.3),
			rack * CFrame.new(index * 1.5, 6.2, 0),
			{ material = Enum.Material.Metal, color = P.gold, collide = false, name = "Hilt" }
		)
	end
end

-- The observatory: a round pink stone tower with a balcony, a gold dome, a telescope and a small
-- turning star on top, the tallest point of the city.
local function observatory(parent: Instance, place: CFrame, building: Building)
	local w, h = building.width, building.height
	local tint = { material = Enum.Material.Limestone, color = Color3.fromRGB(236, 212, 220), name = "Tower" }
	Build.cylinder(parent, h, w, place * CFrame.new(0, h / 2, 0), tint)
	Build.cylinder(parent, 1, w + 3, place * CFrame.new(0, h * 0.72, 0), DARK_STONE)
	Build.cylinder(parent, 5, w - 2, place * CFrame.new(0, h + 2.5, 0), tint)
	Build.ball(parent, w - 2, place * CFrame.new(0, h + 5, 0), GOLD)
	Build.cylinder(
		parent,
		7,
		1.4,
		place * CFrame.new(0, h + 7, -2) * CFrame.Angles(math.rad(-50), 0, 0) * CFrame.new(0, 3, 0),
		{ material = Enum.Material.Metal, color = Color3.fromRGB(170, 130, 70), collide = false, name = "Telescope" }
	)
	Build.block(parent, Vector3.new(3, 5, 0.6), place * CFrame.new(0, 2.5, -w / 2 + 0.1), DOOR)
	for _, height in { h * 0.4, h * 0.6, h * 0.86 } do
		Build.block(parent, Vector3.new(1.2, 3, 0.4), place * CFrame.new(0, height, -w / 2 - 0.05), GLOW)
	end
	Build.cylinder(parent, 3, 0.5, place * CFrame.new(0, h + 10, 0), GOLD)
	local star = Build.model(parent, "Star")
	local gem = crest(star, place * CFrame.new(0, h + 13, 0), 3)
	Build.light(gem, P.crystal, 18, 1)
	star.PrimaryPart = gem
	star.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	star:SetAttribute(World.SPIN_SPEED, -35)
	CollectionService:AddTag(star, World.SPIN_TAG)
end

-- A market stall: posts, a counter with goods and an awning striped in pink and gold that slopes
-- down to the front.
local function stall(parent: Instance, place: CFrame, building: Building, random: Random)
	local w, d, h = building.width, building.depth, building.height
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local height = if sz < 0 then h - 1.2 else h
			Build.cylinder(
				parent,
				height,
				0.5,
				place * CFrame.new(sx * (w / 2 - 0.3), height / 2, sz * (d / 2 - 0.3)),
				TIMBER
			)
		end
	end
	Build.block(parent, Vector3.new(w - 1, 2.4, 1.4), place * CFrame.new(0, 1.2, -d / 2 + 1), PLANKS)
	Build.block(parent, Vector3.new(w - 0.6, 0.3, 1.8), place * CFrame.new(0, 2.55, -d / 2 + 1), TIMBER)
	local goods = {
		Color3.fromRGB(220, 70, 60),
		Color3.fromRGB(240, 190, 60),
		Color3.fromRGB(110, 170, 80),
		Color3.fromRGB(170, 110, 200),
	}
	for index = -1, 1 do
		Build.block(parent, Vector3.new(1.4, 0.8, 1), place * CFrame.new(index * 2.4, 3.1, -d / 2 + 1), {
			material = Enum.Material.Fabric,
			color = goods[random:NextInteger(1, #goods)],
			collide = false,
			shadow = false,
			name = "Goods",
		})
	end
	local stripes = 5
	for index = 0, stripes - 1 do
		Build.block(
			parent,
			Vector3.new(w / stripes + 0.05, 0.15, d + 1.4),
			place * CFrame.new(-w / 2 + w / stripes * (index + 0.5), h - 0.5, -0.4) * CFrame.Angles(math.rad(-12), 0, 0),
			{
				material = Enum.Material.Fabric,
				color = if index % 2 == 0 then P.pink else P.gold,
				collide = false,
				name = "Awning",
			}
		)
	end
end

-- The well: a stone ring with water, two posts and a small roof.
local function well(parent: Instance, place: CFrame, building: Building)
	local w, h = building.width, building.height
	Build.cylinder(parent, 2.6, w, place * CFrame.new(0, 1.3, 0), STONE)
	Build.cylinder(
		parent,
		0.2,
		w - 1.2,
		place * CFrame.new(0, 2.2, 0),
		{ material = Enum.Material.Glass, color = P.water, transparency = 0.2, collide = false, name = "Water" }
	)
	for _, sx in { -1, 1 } do
		Build.block(
			parent,
			Vector3.new(0.5, h - 2, 0.5),
			place * CFrame.new(sx * (w / 2 - 0.4), (h - 2) / 2, 0),
			TIMBER
		)
	end
	Build.gableRoof(parent, place * CFrame.new(0, h - 2, 0), w + 1, 4, 1.8, ROOF)
end

local function buildBuildings(model: Model, city: CFrame, random: Random)
	local folder = Build.folder(model, "Buildings")
	for _, building in C.BUILDINGS do
		local place = city * CFrame.new(building.x, 0, building.z) * CFrame.Angles(0, math.rad(building.facing), 0)
		local piece = Build.model(folder, building.kind)
		if building.kind == "Bank" then
			bank(piece, place, building)
		elseif building.kind == "Tavern" then
			tavern(piece, place, building, random)
		elseif building.kind == "Smithy" then
			smithy(piece, place, building)
		elseif building.kind == "Observatory" then
			observatory(piece, place, building)
		elseif building.kind == "Stall" then
			stall(piece, place, building, random)
		elseif building.kind == "Well" then
			well(piece, place, building)
		else
			house(piece, place, building, random)
		end
	end
end

-- Lamps along the main street and around the square, benches and blossom trees on the square, and
-- barrels and crates by the market and the smithy.
local function buildStreetProps(model: Model, city: CFrame, random: Random)
	local folder = Build.folder(model, "Props")
	local lampEdge = C.STREET_WIDTH / 2 + 3
	local x = -C.WALL_HALF_X + 8
	while x <= C.WALL_HALF_X - 8 do
		if math.abs(x) >= 10 then
			-- The arm of a lamp leans over the street.
			Props.lamp(
				folder,
				city * CFrame.new(x, GROUND_TOP, -lampEdge) * CFrame.Angles(0, math.pi, 0),
				C.LAMP_HEIGHT
			)
			Props.lamp(folder, city * CFrame.new(x, GROUND_TOP, lampEdge), C.LAMP_HEIGHT)
		end
		x += C.LAMP_SPACING
	end

	local plaza = city * CFrame.new(C.PLAZA.x, SQUARE_TOP, C.PLAZA.z)
	local function onRing(angle: number, radius: number): CFrame
		local a = math.rad(angle)
		return plaza * CFrame.new(math.cos(a) * radius, 0, math.sin(a) * radius)
	end
	for index = 1, C.PLAZA_LAMPS do
		Props.lamp(folder, onRing(45 + (index - 1) * 360 / C.PLAZA_LAMPS, C.PLAZA.radius - 2), C.LAMP_HEIGHT)
	end
	for _, angle in { 0, 180 } do
		local spot = onRing(angle, 13)
		Props.bench(folder, CFrame.lookAt(spot.Position, plaza.Position))
	end
	for _, angle in { 20, 160, 200, 340 } do
		local spot = onRing(angle, C.PLAZA.radius - 5)
		Build.cylinder(folder, 1, 5, spot * CFrame.new(0, 0.5, 0), DARK_STONE)
		Props.tree(folder, spot * CFrame.new(0, 1, 0), 7, 7, random, true)
	end

	local market = city * CFrame.new(C.MARKET.x, MARKET_TOP, C.MARKET.z)
	for _, spot in { { -28, -14 }, { 28, -16 }, { -28, 16 }, { 28, 14 } } do
		Props.barrel(folder, market * CFrame.new(spot[1], 0, spot[2]))
		Props.crate(folder, market * CFrame.new(spot[1] + (if spot[1] < 0 then -3 else 3), 0, spot[2] + 1), 2.2)
	end
end

-- Builds the city on `city` (its center, on the ground, X along the road). Returns the model,
-- not yet in the world.
function CityBuilder.build(city: CFrame, options: Options?): Model
	local random = Random.new(1)
	local model = Build.model(nil, "Stardawn")
	buildGround(model, city)
	buildWalls(model, city, options or {})
	buildMonument(model, city)
	buildBuildings(model, city, random)
	buildStreetProps(model, city, random)
	model.WorldPivot = city
	CollectionService:AddTag(model, World.CITY_TAG)
	return model
end

return table.freeze(CityBuilder)
