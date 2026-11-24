--!strict
--[[
	Props.luau
	The small pieces the provisional world reuses (US-052 to US-054). Nature: trees, bushes, rocks,
	crystals and dead trees. The city: street lamps, banners, torches, barrels, crates and benches.
	Camps: tents and campfires. Each one stands on `base`, a frame on the ground facing where the
	piece's front should look (-Z). Trunks, rocks and furniture collide; leaves and other light
	decoration do not.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CityConfig = require(ReplicatedStorage.Shared.Config.City)
local SceneryConfig = require(ReplicatedStorage.Shared.Config.Scenery)
local Build = require(script.Parent.Build)

local CITY = CityConfig.PALETTE
local NATURE = SceneryConfig.PALETTE

local Props = {}

local function pick<T>(list: { T }, random: Random): T
	return list[random:NextInteger(1, #list)]
end

-- A frame turned by random angles, for rocks and crystals.
local function tumbled(base: CFrame, random: Random, maxTilt: number): CFrame
	return base
		* CFrame.Angles(
			math.rad(random:NextNumber(-maxTilt, maxTilt)),
			math.rad(random:NextNumber(0, 360)),
			math.rad(random:NextNumber(-maxTilt, maxTilt))
		)
end

-- A big tree: a trunk and a crown of three balls of leaves (or of pink blossom).
function Props.tree(parent: Instance, base: CFrame, height: number, crown: number, random: Random, blossom: boolean)
	local trunkWidth = math.max(1.6, height * 0.09)
	Build.cylinder(
		parent,
		height,
		trunkWidth,
		base * CFrame.new(0, height / 2, 0),
		{ material = Enum.Material.Wood, color = NATURE.trunk, name = "Trunk" }
	)
	local leaves = if blossom then pick(NATURE.blossom, random) else pick(NATURE.leaves, random)
	local style =
		{ material = Enum.Material.LeafyGrass, color = leaves, collide = false, shadow = true, name = "Leaves" }
	Build.ball(parent, crown, base * CFrame.new(0, height + crown * 0.15, 0), style)
	for _ = 1, 2 do
		local angle = random:NextNumber(0, math.pi * 2)
		local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * crown * 0.38
		Build.ball(
			parent,
			crown * random:NextNumber(0.6, 0.75),
			base * CFrame.new(offset.X, height - crown * 0.05, offset.Z),
			style
		)
	end
end

-- A bush: one or two balls of leaves, without collision.
function Props.bush(parent: Instance, base: CFrame, size: number, random: Random)
	local style = {
		material = Enum.Material.LeafyGrass,
		color = pick(NATURE.leaves, random),
		collide = false,
		shadow = false,
		name = "Bush",
	}
	Build.ball(parent, size, base * CFrame.new(0, size * 0.3, 0), style)
	if random:NextNumber() < 0.5 then
		Build.ball(parent, size * 0.7, base * CFrame.new(size * 0.45, size * 0.2, size * 0.2), style)
	end
end

-- A rock: a tilted block sunk in the ground (and a smaller one beside it, sometimes). Small rocks
-- do not collide.
function Props.rock(parent: Instance, base: CFrame, size: number, random: Random, color: Color3?)
	local style = {
		material = if random:NextNumber() < 0.5 then Enum.Material.Rock else Enum.Material.Slate,
		color = color or NATURE.rock,
		collide = size >= 5,
		shadow = size >= 5,
		name = "Rock",
	}
	local scale = Vector3.new(random:NextNumber(0.8, 1.3), random:NextNumber(0.5, 0.9), random:NextNumber(0.8, 1.3))
	Build.block(parent, scale * size, tumbled(base * CFrame.new(0, size * 0.2, 0), random, 25), style)
	if random:NextNumber() < 0.4 then
		local small = size * random:NextNumber(0.35, 0.55)
		Build.block(
			parent,
			Vector3.new(small, small * 0.7, small),
			tumbled(base * CFrame.new(size * 0.6, small * 0.2, size * 0.3), random, 30),
			style
		)
	end
end

-- A cluster of crystals (Stardawn's ore, Mundo e Terreno tab): long glassy shards leaning out from
-- one point. `glow` adds a light.
function Props.crystals(parent: Instance, base: CFrame, size: number, random: Random, color: Color3, glow: boolean)
	local style = {
		material = Enum.Material.Glass,
		color = color,
		transparency = 0.15,
		reflectance = 0.1,
		collide = false,
		shadow = false,
		name = "Crystal",
	}
	local count = random:NextInteger(3, 5)
	local first: Part? = nil
	for index = 1, count do
		local length = size * random:NextNumber(0.6, 1.2)
		local width = size * random:NextNumber(0.15, 0.25)
		local lean = if index == 1 then 0 else random:NextNumber(15, 38)
		local turn = random:NextNumber(0, 360)
		local shard = Build.block(
			parent,
			Vector3.new(width, length, width),
			base
				* CFrame.Angles(0, math.rad(turn), 0)
				* CFrame.Angles(math.rad(lean), 0, 0)
				* CFrame.new(0, length / 2 - size * 0.15, 0)
				* CFrame.Angles(0, math.rad(45), 0),
			style
		)
		first = first or shard
	end
	if glow and first then
		Build.light(first, color, size * 2.5, 1)
	end
end

-- A dead tree: a dark trunk with two or three bare branches.
function Props.deadTree(parent: Instance, base: CFrame, height: number, random: Random)
	local style = { material = Enum.Material.Wood, color = NATURE.deadWood, name = "DeadTree" }
	Build.cylinder(parent, height, 1.3, base * CFrame.new(0, height / 2, 0), style)
	for _ = 1, random:NextInteger(2, 3) do
		local length = height * random:NextNumber(0.3, 0.5)
		local from = height * random:NextNumber(0.55, 0.9)
		Build.cylinder(
			parent,
			length,
			0.6,
			base
				* CFrame.new(0, from, 0)
				* CFrame.Angles(0, math.rad(random:NextNumber(0, 360)), 0)
				* CFrame.Angles(math.rad(random:NextNumber(35, 65)), 0, 0)
				* CFrame.new(0, length / 2, 0),
			{ material = Enum.Material.Wood, color = NATURE.deadWood, collide = false, name = "Branch" }
		)
	end
end

-- A street lamp: a pole, an arm and a lantern with a warm light.
function Props.lamp(parent: Instance, base: CFrame, height: number)
	local metal = { material = Enum.Material.Metal, color = CITY.metal, name = "Lamp" }
	Build.cylinder(parent, height, 0.5, base * CFrame.new(0, height / 2, 0), metal)
	Build.block(parent, Vector3.new(0.3, 0.3, 2), base * CFrame.new(0, height - 0.3, -0.9), metal)
	local lantern = Build.block(parent, Vector3.new(1.2, 1.6, 1.2), base * CFrame.new(0, height - 1.3, -1.7), {
		material = Enum.Material.Glass,
		color = CITY.windowGlow,
		transparency = 0.3,
		collide = false,
		name = "Lantern",
	})
	Build.block(parent, Vector3.new(1.5, 0.3, 1.5), base * CFrame.new(0, height - 0.35, -1.7), metal)
	Build.light(lantern, CITY.lampLight, 18, 1.2)
end

-- A banner of Stardawn hanging from a gold rod: pink cloth with three tails and the gold star
-- (Facções tab: "pink three-pointed flag with the faction's medallion"). `top` is the center of the
-- rod; the cloth faces the frame's -Z.
function Props.banner(parent: Instance, top: CFrame, width: number, height: number)
	local gold = { material = Enum.Material.Metal, color = CITY.gold, collide = false, name = "Banner" }
	local cloth = { material = Enum.Material.Fabric, color = CITY.pink, collide = false, name = "Banner" }
	Build.cylinder(parent, width + 1, 0.4, top * CFrame.Angles(0, 0, math.rad(90)), gold)
	Build.block(parent, Vector3.new(width, height, 0.2), top * CFrame.new(0, -height / 2 - 0.2, 0), cloth)
	local tail = height * 0.18
	for index = -1, 1 do
		Build.block(
			parent,
			Vector3.new(width / 5, tail, 0.2),
			top * CFrame.new(index * width * 0.36, -height - 0.2 - tail / 2, 0),
			cloth
		)
	end
	Build.star(parent, top * CFrame.new(0, -height * 0.42, 0), width * 0.45, 0.3, gold)
end

-- A torch on a wall: `cframe` is where the flame burns.
function Props.torch(parent: Instance, cframe: CFrame)
	local wood = { material = Enum.Material.Wood, color = CITY.timber, collide = false, name = "Torch" }
	Build.cylinder(parent, 2.4, 0.4, cframe * CFrame.new(0, -1.3, 0), wood)
	local head = Build.block(
		parent,
		Vector3.new(0.6, 0.6, 0.6),
		cframe,
		{ material = Enum.Material.Metal, color = CITY.metal, collide = false, name = "Torch" }
	)
	Build.fire(head, 2.5, 6, Color3.fromRGB(255, 170, 60), Color3.fromRGB(255, 80, 30))
	Build.light(head, Color3.fromRGB(255, 160, 80), 16, 1.6)
end

function Props.barrel(parent: Instance, base: CFrame)
	Build.cylinder(
		parent,
		3,
		2.4,
		base * CFrame.new(0, 1.5, 0),
		{ material = Enum.Material.Wood, color = Color3.fromRGB(120, 84, 56), name = "Barrel" }
	)
	local ring =
		{ material = Enum.Material.Metal, color = CITY.metal, collide = false, shadow = false, name = "Barrel" }
	Build.cylinder(parent, 0.2, 2.5, base * CFrame.new(0, 0.6, 0), ring)
	Build.cylinder(parent, 0.2, 2.5, base * CFrame.new(0, 2.4, 0), ring)
end

function Props.crate(parent: Instance, base: CFrame, size: number)
	Build.block(
		parent,
		Vector3.new(size, size, size),
		base * CFrame.new(0, size / 2, 0),
		{ material = Enum.Material.WoodPlanks, color = Color3.fromRGB(150, 112, 74), name = "Crate" }
	)
end

-- A wooden bench whose seat faces the frame's -Z.
function Props.bench(parent: Instance, base: CFrame)
	local wood = { material = Enum.Material.WoodPlanks, color = CITY.timber, name = "Bench" }
	Build.block(parent, Vector3.new(5, 0.4, 1.6), base * CFrame.new(0, 1.6, 0), wood)
	Build.block(parent, Vector3.new(5, 1.4, 0.3), base * CFrame.new(0, 2.5, 0.7), wood)
	for side = -1, 1, 2 do
		Build.block(parent, Vector3.new(0.4, 1.4, 1.4), base * CFrame.new(side * 2.1, 0.7, 0), wood)
	end
end

-- A camp tent: two sloped canvas sides over a ridge pole, its opening toward the frame's -Z.
function Props.tent(parent: Instance, base: CFrame, color: Color3?)
	local canvas = { material = Enum.Material.Fabric, color = color or NATURE.tent, name = "Tent" }
	-- The roof helper runs the ridge along X: turn it so the ridge runs front to back.
	Build.gableRoof(parent, base * CFrame.Angles(0, math.rad(90), 0), 9, 7, 5, canvas)
	Build.cylinder(
		parent,
		9.6,
		0.3,
		base * CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(90), 0, 0),
		{ material = Enum.Material.Wood, color = NATURE.trunk, collide = false, name = "Tent" }
	)
end

-- A campfire: a ring of stones, two logs and the fire.
function Props.campfire(parent: Instance, base: CFrame)
	Build.cylinder(
		parent,
		0.6,
		4,
		base * CFrame.new(0, 0.3, 0),
		{ material = Enum.Material.Slate, color = NATURE.darkRock, name = "Campfire" }
	)
	local log = { material = Enum.Material.Wood, color = NATURE.deadWood, collide = false, name = "Campfire" }
	local first =
		Build.cylinder(parent, 3.2, 0.6, base * CFrame.new(0, 0.9, 0) * CFrame.Angles(0, 0, math.rad(90)), log)
	Build.cylinder(
		parent,
		3.2,
		0.6,
		base * CFrame.new(0, 1, 0) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(0, 0, math.rad(90)),
		log
	)
	Build.fire(first, 4, 7, Color3.fromRGB(255, 160, 60), Color3.fromRGB(255, 70, 20))
	Build.light(first, Color3.fromRGB(255, 150, 70), 20, 2)
end

return table.freeze(Props)
