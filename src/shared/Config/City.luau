--!strict
--[[
	Config/City.luau
	The provisional city of Stardawn (US-052), built by code while the place has no city made in
	Studio. It has walls with towers and two gates on the road, and the Star Square with the
	monument; around them stand the bank, the market, the smithy, the tavern, the observatory and
	the houses.

	Stardawn is "the star city", in pink and gold. Its crest is an eight-pointed star of pink crystal
	with a gold outline and a gem in the center (Facções tab).

	Positions are studs from the city's center, on its ground:
	- x runs along the road: +x toward the Blue zone, -x toward the Yellow one;
	- z runs across it: -z is north.
	`facing` is where a building's door looks, in degrees: 0 north, 90 west, 180 south, 270 east.

	The layout is the dev's (2026-11-24, DECISOES-DELEGADAS). Davi can move things here or rebuild
	the city in Studio.
]]

-- A gate in a wall (East, West, North or South), `offset` studs along the wall from its middle.
export type Gate = { side: string, offset: number }

-- One building or structure of the city.
export type Building = {
	kind: string,
	x: number,
	z: number,
	facing: number,
	width: number,
	depth: number,
	height: number,
	sign: string?,
}

-- Kinds: Bank, Tavern, Smithy, Observatory, House, Stall and Well. The signs are game text.
local BUILDINGS: { Building } = {
	{ kind = "Bank", x = 0, z = -86, facing = 180, width = 34, depth = 22, height = 16, sign = "Banco de Stardawn" },
	{
		kind = "Tavern",
		x = 46,
		z = -88,
		facing = 180,
		width = 22,
		depth = 16,
		height = 13,
		sign = "Taverna da Estrela Cadente",
	},
	{
		kind = "Observatory",
		x = -46,
		z = -92,
		facing = 180,
		width = 12,
		depth = 12,
		height = 30,
		sign = "Observatório",
	},
	{ kind = "Smithy", x = -46, z = 40, facing = 270, width = 22, depth = 16, height = 12, sign = "Ferraria" },
	{ kind = "House", x = -46, z = -36, facing = 270, width = 16, depth = 13, height = 11 },
	{ kind = "House", x = 46, z = -36, facing = 90, width = 16, depth = 13, height = 11 },
	{ kind = "House", x = -48, z = -62, facing = 270, width = 14, depth = 12, height = 10 },
	{ kind = "House", x = 48, z = -62, facing = 90, width = 14, depth = 12, height = 10 },
	{ kind = "House", x = 50, z = 28, facing = 0, width = 14, depth = 12, height = 10 },
	{ kind = "House", x = 50, z = 62, facing = 90, width = 14, depth = 12, height = 11 },
	{ kind = "House", x = -46, z = 86, facing = 0, width = 15, depth = 12, height = 10 },
	{ kind = "House", x = -14, z = 94, facing = 0, width = 14, depth = 12, height = 11 },
	{ kind = "House", x = 18, z = 94, facing = 0, width = 14, depth = 12, height = 10 },
	{ kind = "House", x = 50, z = 94, facing = 0, width = 14, depth = 12, height = 11 },
	{ kind = "Stall", x = -12, z = 26, facing = 0, width = 9, depth = 6, height = 7 },
	{ kind = "Stall", x = 8, z = 26, facing = 0, width = 9, depth = 6, height = 7 },
	{ kind = "Stall", x = 28, z = 26, facing = 0, width = 9, depth = 6, height = 7 },
	{ kind = "Stall", x = -12, z = 54, facing = 180, width = 9, depth = 6, height = 7 },
	{ kind = "Stall", x = 8, z = 54, facing = 180, width = 9, depth = 6, height = 7 },
	{ kind = "Stall", x = 28, z = 54, facing = 180, width = 9, depth = 6, height = 7 },
	{ kind = "Well", x = 16, z = 76, facing = 0, width = 6, depth = 6, height = 8 },
}
for _, building in BUILDINGS do
	table.freeze(building)
end

return table.freeze({
	-- Builds the provisional city on each City zone of a place that has no city (tag CityModel).
	BUILD_PROVISIONAL = true,

	-- Walls: half sizes from the center (studs), height and thickness; towers on the corners and on
	-- both sides of each gate; merlons along the tops.
	WALL_HALF_X = 68,
	WALL_HALF_Z = 118,
	WALL_HEIGHT = 16,
	WALL_THICKNESS = 4,
	-- The gates (US-056): east and west on the main street, south toward the Blue valley, and north
	-- beside the bank, which stands in the middle of the north side.
	GATES = table.freeze({
		table.freeze({ side = "East", offset = 0 }),
		table.freeze({ side = "West", offset = 0 }),
		table.freeze({ side = "South", offset = 0 }),
		table.freeze({ side = "North", offset = 26 }),
	}) :: { Gate },
	GATE_WIDTH = 16,
	GATE_HEIGHT = 20,
	TOWER_SIZE = 12,
	GATE_TOWER_HEIGHT = 28,
	CORNER_TOWER_HEIGHT = 24,
	MERLON_SPACING = 6,
	MERLON_SIZE = 2.5,

	-- Streets: the main street joins the east and west gates, and the north and south streets end at
	-- it. The Star Square is north of it, with the monument, and the market square south of it. The
	-- center of the city stays free: it is the city's return point (EP-009).
	STREET_WIDTH = 12,
	PLAZA = table.freeze({ x = 0, z = -38, radius = 24 }),
	MARKET = table.freeze({ x = 8, z = 40, width = 64, depth = 44 }),
	-- Street lamps: along the main street (both sides) and around the square.
	LAMP_SPACING = 20,
	LAMP_HEIGHT = 9,
	PLAZA_LAMPS = 4,

	-- The Star of the monument: size, height above the ground and how it turns on the client.
	STAR_SIZE = 7,
	STAR_HEIGHT = 15,
	STAR_SPIN_SPEED = 20,
	STAR_BOB_HEIGHT = 0.6,

	BUILDINGS = table.freeze(BUILDINGS),

	-- Colors of the city: pink and gold (Facções tab), on light stone and plaster.
	PALETTE = table.freeze({
		pink = Color3.fromRGB(226, 110, 170),
		gold = Color3.fromRGB(240, 196, 90),
		crystal = Color3.fromRGB(255, 125, 205),
		gem = Color3.fromRGB(255, 225, 245),
		marble = Color3.fromRGB(236, 228, 222),
		stone = Color3.fromRGB(184, 174, 164),
		darkStone = Color3.fromRGB(112, 106, 102),
		plaster = Color3.fromRGB(234, 224, 206),
		timber = Color3.fromRGB(96, 66, 46),
		roof = Color3.fromRGB(158, 76, 98),
		earth = Color3.fromRGB(150, 128, 100),
		cobble = Color3.fromRGB(150, 142, 136),
		windowGlow = Color3.fromRGB(255, 205, 140),
		lampLight = Color3.fromRGB(255, 200, 140),
		water = Color3.fromRGB(90, 150, 200),
		metal = Color3.fromRGB(58, 58, 64),
	}),
})
