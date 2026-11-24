--!strict
--[[
	Config/Scenery.luau
	The provisional scenery of the test layout (US-054), built by code while the place has no terrain
	and zones made in Studio. It follows the Mundo e Terreno tab: Stardawn is mountainous, with
	vegetation, big trees and plenty of ore.
	- Ground: each zone shows its risk on the floor. The Blue is a meadow, the Yellow golden grass,
	  the Red dark rock.
	- A road joins the spawn, the city and the zones.
	- Border markers stand where the risk grows.
	- Mountains close the edges, with an invisible wall that keeps players in.
	- Each zone gets its own nature. The Blue has trees, some with pink blossom. The Yellow has hills,
	  ruins and pink crystals, the region's ore. The Red has stone spires, dead trees and red
	  crystals.
	Densities are items per 10,000 studs² of zone. The scenery keeps clear of the road, the city and
	everything of gameplay (enemies, camps, entrances, chests, dummies and return points). The values
	are the dev's (2026-11-24, DECISOES-DELEGADAS).
]]

local NATURE: { [string]: any } = {
	Blue = table.freeze({ trees = 1.1, blossom = 0.25, bushes = 1.6, rocks = 0.8 }),
	City = table.freeze({ trees = 0.6, blossom = 0.4, bushes = 0.8, rocks = 0.3 }),
	Yellow = table.freeze({
		trees = 0.55,
		blossom = 0.1,
		bushes = 0.6,
		rocks = 1.2,
		crystals = 0.6,
		hills = 8,
		ruins = 3,
	}),
	Red = table.freeze({ deadTrees = 0.8, spires = 0.7, rocks = 1, crystals = 0.5, towers = 2 }),
}

local GROUNDS: { [string]: any } = {
	Yellow = table.freeze({ material = Enum.Material.Grass, color = Color3.fromRGB(170, 160, 84) }),
	Red = table.freeze({ material = Enum.Material.Slate, color = Color3.fromRGB(96, 72, 68) }),
	Black = table.freeze({ material = Enum.Material.Basalt, color = Color3.fromRGB(46, 42, 46) }),
}

local ROADS: { [string]: any } = {
	Blue = table.freeze({ material = Enum.Material.Ground, color = Color3.fromRGB(140, 112, 82) }),
	City = table.freeze({ material = Enum.Material.Ground, color = Color3.fromRGB(140, 112, 82) }),
	Yellow = table.freeze({ material = Enum.Material.Pebble, color = Color3.fromRGB(162, 146, 118) }),
	Red = table.freeze({ material = Enum.Material.Slate, color = Color3.fromRGB(74, 66, 66) }),
	Black = table.freeze({ material = Enum.Material.Basalt, color = Color3.fromRGB(40, 38, 40) }),
}

local CRYSTALS: { [string]: Color3 } = {
	Yellow = Color3.fromRGB(255, 125, 205),
	Red = Color3.fromRGB(200, 40, 80),
	Black = Color3.fromRGB(120, 60, 200),
}

return table.freeze({
	-- Builds the scenery when the test layout of the zones is in use (no zone regions in the place)
	-- and the place has no scenery yet (tag Scenery).
	BUILD_TEST_SCENERY = true,
	-- The same seed always builds the same scenery.
	SEED = 2026,

	-- The Blue zone (and the rest of the baseplate) is painted as a meadow; the other zones get a
	-- ground of their own.
	MEADOW = table.freeze({ material = Enum.Material.Grass, color = Color3.fromRGB(98, 142, 72) }),
	GROUNDS = table.freeze(GROUNDS),

	-- The road: where it starts (studs from the spawn), its width and its look in each zone.
	ROAD_START = 8,
	ROAD_WIDTH = 10,
	ROADS = table.freeze(ROADS),

	-- The signpost by the spawn: studs from the spawn along the zones (left) and across (z).
	SIGNPOST = table.freeze({ left = 16, z = -10 }),

	-- Border markers: pillars and a sign over the road where the risk grows, and posts along the
	-- whole border every BORDER_POST_SPACING studs.
	BORDER_POST_SPACING = 40,

	NATURE = table.freeze(NATURE),
	CRYSTALS = table.freeze(CRYSTALS),
	-- At most this many crystal clusters glow (lights cost frames).
	MAX_CRYSTAL_LIGHTS = 8,

	-- Gameplay points the scenery keeps clear, by CollectionService tag, and the studs kept free
	-- around each one: enemy spawns, dungeon entrances, camps (CampService's tag), chests, training
	-- dummies and other targets, and return points.
	AVOID_TAGS = table.freeze({
		EnemySpawn = 20,
		DungeonEntrance = 22,
		GroupDungeonEntrance = 22,
		Camp = 34,
		LootChest = 16,
		Target = 16,
		ReturnPoint = 16,
	}),
	CAMP_TAG = "Camp",

	-- Studs kept free: around the road's center line, around the spawn, outside the city's walls,
	-- between two props and inside each zone's edges.
	CLEAR_ROAD = 14,
	CLEAR_SPAWN = 30,
	CLEAR_CITY = 12,
	PROP_SPACING = 4,
	EDGE_MARGIN = 10,

	-- Mountains around the play area: how far outside its edges they stand, the space between them
	-- and their size. The invisible wall stands BOUNDARY_MARGIN studs outside the zones.
	MOUNTAIN_DISTANCE = 75,
	MOUNTAIN_SPACING = 95,
	MOUNTAIN_MIN_SIZE = 70,
	MOUNTAIN_MAX_SIZE = 150,
	BOUNDARY_MARGIN = 5,
	BOUNDARY_HEIGHT = 400,

	PALETTE = table.freeze({
		trunk = Color3.fromRGB(108, 78, 56),
		deadWood = Color3.fromRGB(72, 58, 50),
		leaves = table.freeze({
			Color3.fromRGB(76, 128, 58),
			Color3.fromRGB(92, 140, 62),
			Color3.fromRGB(64, 112, 54),
		}),
		blossom = table.freeze({ Color3.fromRGB(246, 170, 205), Color3.fromRGB(236, 150, 190) }),
		rock = Color3.fromRGB(128, 122, 116),
		darkRock = Color3.fromRGB(70, 62, 62),
		mountain = Color3.fromRGB(120, 112, 106),
		snow = Color3.fromRGB(242, 244, 250),
		ruin = Color3.fromRGB(150, 144, 128),
		tent = Color3.fromRGB(140, 76, 62),
	}),
})
