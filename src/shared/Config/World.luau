--!strict
--[[
	Config/World.luau
	The world of Stardawn that the generator builds in Studio (US-055). Davi asked for it on
	2026-11-24: about 2.5 minutes on foot to cross each zone, and a map that spreads to the sides
	and is "less square".
	- The city is at the origin.
	- The Blue valley (the tutorial) lies south of the city.
	- The Yellow hills wrap around the city.
	- The Red peaks spread to the west, north and east.
	- Mountains close the edges.

	Coordinates are world studs: x grows to the east, z to the south. Each zone is a union of
	circles { x, z, radius }. Where circles of different zones overlap, the smaller circle wins, as
	with the zone regions at runtime. So the zones are listed from the outermost to the innermost,
	and inner zones use smaller circles than the zones around them.

	The values are the dev's starting point (DECISOES-DELEGADAS), to be tuned with Davi's prints.
]]

export type ZoneSpec = { id: string, kind: string, tier: number, name: string, circles: { { number } } }
export type Relief = {
	-- Height (studs) and size of the hills, height and size of the stone ridges.
	hills: number,
	hillScale: number,
	ridges: number,
	ridgeScale: number,
	-- Terrain materials: the ground, a second ground in patches (or nil) and the paths.
	material: Enum.Material,
	patches: Enum.Material?,
	path: Enum.Material,
}

-- From the outermost zone to the innermost.
local ZONES: { ZoneSpec } = {
	{
		id = "PicosDeStardawn",
		kind = "Red",
		tier = 3,
		name = "Picos de Stardawn",
		circles = {
			{ 0, -3700, 1650 },
			{ -3900, -1700, 1650 },
			{ 3900, -1700, 1650 },
			{ -4300, 900, 1450 },
			{ 4300, 900, 1450 },
		},
	},
	{
		id = "ColinasDeStardawn",
		kind = "Yellow",
		tier = 2,
		name = "Colinas de Stardawn",
		circles = {
			{ 0, -900, 1600 },
			{ -2000, -150, 1400 },
			{ 2000, -150, 1400 },
			{ -1850, 1250, 1250 },
			{ 1850, 1250, 1250 },
			{ -1300, -1700, 1000 },
			{ 1300, -1700, 1000 },
		},
	},
	{
		id = "CamposDeStardawn",
		kind = "Blue",
		tier = 1,
		name = "Campos de Stardawn",
		circles = { { 0, 1500, 1200 }, { -700, 2150, 700 }, { 650, 1950, 650 } },
	},
	{ id = "Stardawn", kind = "City", tier = 1, name = "Stardawn", circles = { { 0, 0, 300 } } },
}

local RELIEF: { [string]: Relief } = {
	City = {
		hills = 0,
		hillScale = 400,
		ridges = 0,
		ridgeScale = 520,
		material = Enum.Material.LeafyGrass,
		path = Enum.Material.Ground,
	},
	Blue = {
		hills = 32,
		hillScale = 380,
		ridges = 0,
		ridgeScale = 520,
		material = Enum.Material.LeafyGrass,
		path = Enum.Material.Ground,
	},
	Yellow = {
		hills = 72,
		hillScale = 440,
		ridges = 16,
		ridgeScale = 600,
		material = Enum.Material.Grass,
		patches = Enum.Material.Ground,
		path = Enum.Material.Ground,
	},
	Red = {
		hills = 75,
		hillScale = 400,
		ridges = 95,
		ridgeScale = 640,
		material = Enum.Material.Rock,
		patches = Enum.Material.Basalt,
		path = Enum.Material.Slate,
	},
}

-- Paths from the city's gates to every zone, as lines of { x, z } points.
local PATHS: { { { number } } } = {
	{ { 0, 124 }, { 0, 700 }, { 150, 1300 }, { 0, 1900 }, { 0, 2350 } },
	{ { 76, 0 }, { 800, -100 }, { 1900, -300 }, { 2900, 200 }, { 3800, 700 }, { 4600, 900 } },
	{ { -76, 0 }, { -800, 100 }, { -1900, -250 }, { -2900, 150 }, { -3800, 650 }, { -4600, 900 } },
	{ { 26, -126 }, { 100, -700 }, { -200, -1400 }, { 100, -2200 }, { 0, -3000 }, { -300, -3800 }, { 0, -4500 } },
	{ { 100, -2200 }, { -1500, -2100 }, { -3000, -1700 }, { -3900, -1700 } },
	{ { 100, -2200 }, { 1500, -2100 }, { 3000, -1700 }, { 3900, -1700 } },
}

-- Groups of enemies in each zone: how many, the share of elites and the mixes they draw from
-- ({ enemy kind, how many }).
local ENEMIES: { [string]: any } = {
	Blue = { groups = 14, eliteChance = 0, mixes = { { "BanditThug", 1 }, { "BanditThug", 2 }, { "BanditArcher", 1 } } },
	Yellow = {
		groups = 26,
		eliteChance = 0.2,
		mixes = { { "BanditThug", 2 }, { "BanditArcher", 1 }, { "BanditBomber", 1 }, { "BanditThug", 1 } },
	},
	Red = {
		groups = 30,
		eliteChance = 0.35,
		mixes = { { "BanditThug", 2 }, { "BanditArcher", 2 }, { "BanditBomber", 1 }, { "BanditThug", 3 } },
	},
}

-- Nature of each zone, in items per 10,000 studs² (or counts, for ruins and towers): fewer than in
-- the test scenery, since the zones are far bigger.
local NATURE: { [string]: any } = {
	City = { trees = 0.4, blossom = 0.4, bushes = 0.5, rocks = 0.2 },
	Blue = { trees = 0.45, blossom = 0.25, bushes = 0.6, rocks = 0.3 },
	Yellow = { trees = 0.22, blossom = 0.08, bushes = 0.25, rocks = 0.3, crystals = 0.12, ruins = 8 },
	Red = { deadTrees = 0.2, spires = 0.12, rocks = 0.3, crystals = 0.1, towers = 6 },
}

return table.freeze({
	ZONES = ZONES,
	RELIEF = RELIEF,
	PATHS = PATHS,

	-- The city: its center, the height of its plateau and how far it stays flat.
	CITY = { x = 0, z = 0, height = 40, flat = 210, blend = 170 },
	-- The spawn: at the far end of the Blue valley, on a small flat ground, facing the city.
	SPAWN = { x = 0, z = 2350, flat = 60, blend = 80 },

	TERRAIN = {
		SEED = 7.31,
		-- Ground height with no relief, and the wide swells over the whole map (size, height).
		BASE_HEIGHT = 30,
		SWELL_SCALE = 1700,
		SWELL_HEIGHT = 85,
		-- Studs over which one zone's relief turns into the next one's.
		BLEND = 320,
		-- Mountains beyond the zones: they start rising this far inside the edge, rise over this many
		-- studs outside, and reach this height plus their peaks.
		EDGE_INSIDE = 100,
		EDGE_RISE = 380,
		EDGE_HEIGHT = 330,
		EDGE_PEAKS = 260,
		EDGE_SCALE = 700,
		-- How far beyond the zones the terrain goes.
		MARGIN = 700,
		-- Snow above this height, rock on slopes steeper than this (degrees).
		SNOW_HEIGHT = 520,
		ROCK_SLOPE = 40,
		-- Paths: width of the beaten ground and how far the relief fades into it.
		PATH_WIDTH = 12,
		PATH_FADE = 60,
		-- How much the edge between two zones' grounds wanders (studs).
		BORDER_NOISE = 50,
		-- Studs of terrain under the lowest ground of each chunk.
		THICKNESS = 24,
		-- Voxels per chunk side, and studs between the height samples.
		CHUNK = 32,
		GRID = 8,
		-- Chunks written between two pauses (Studio stays responsive and prints the progress).
		CHUNKS_PER_PAUSE = 8,
		-- Colors of the terrain materials.
		COLORS = {
			LeafyGrass = Color3.fromRGB(96, 140, 70),
			Grass = Color3.fromRGB(170, 160, 84),
			Ground = Color3.fromRGB(140, 112, 82),
			Rock = Color3.fromRGB(122, 114, 108),
			Basalt = Color3.fromRGB(78, 64, 62),
			Slate = Color3.fromRGB(80, 72, 72),
			Snow = Color3.fromRGB(242, 244, 250),
		},
	},

	-- Zone regions: cylinders this tall (studs), centered at this height.
	REGION_HEIGHT = 2400,
	REGION_CENTER_Y = 300,

	ENEMIES = ENEMIES,
	-- Studs between two enemy groups, and the radius each group spawns in.
	ENEMY_SPACING = 220,
	ENEMY_RADIUS = 6,
	-- Camps of elites for groups (Config/Camps): how many in each zone, and studs between them.
	CAMPS = { Yellow = 2, Red = 2 },
	CAMP_SPACING = 900,
	-- Solo dungeon entrances in each zone, and the zone of the group dungeon's entrance.
	DUNGEON_ENTRANCES = { Blue = 3, Yellow = 3, Red = 3 },
	ENTRANCE_SPACING = 600,
	GROUP_DUNGEON_ZONE = "Yellow",

	NATURE = NATURE,
	-- Studs kept free: around the paths, the city's center, the spawn and every gameplay point; and
	-- the steepest ground (degrees) anything is placed on.
	CLEAR_PATH = 30,
	CLEAR_CITY = 420,
	CLEAR_SPAWN = 160,
	CLEAR_POINT = 30,
	MAX_SLOPE = 30,
	-- Return points stand this far inside a zone, where each path enters it.
	RETURN_INSIDE = 40,

	-- The same seed always places the same things.
	SEED = 2026,
})
