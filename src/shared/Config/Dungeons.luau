--!strict
--[[
	Config/Dungeons.luau
	The random solo dungeon of the M1 (EP-010, Dungeons tab). Where the tab's tuning table and its
	text disagreed, the design doc's values are used (3 entrances, 60 and 90 s, 3 to 5 rooms):
	decided by the dev under Davi's delegation (2026-11-23).
]]

-- Seconds an entrance stays open after the last player went in, by zone kind.
local ENTRANCE_CLOSE_TIME: { [string]: number } = { Blue = 60, Yellow = 60, City = 60, Red = 90, Black = 90 }

return table.freeze({
	-- Entrances (US-042): how many entrance points of each zone are open at a time.
	ACTIVE_ENTRANCES_PER_ZONE = 3,
	ENTRANCE_CLOSE_TIME = table.freeze(ENTRANCE_CLOSE_TIME),

	-- Layout (US-041): combat rooms (the elite one included) from the entrance to the boss.
	MIN_COMBAT_ROOMS = 3,
	MAX_COMBAT_ROOMS = 5,

	-- Placeholder rooms until the rooms built in Studio exist: size of a room and of the corridor
	-- between two rooms (studs).
	ROOM_SIZE = Vector3.new(60, 20, 60),
	CORRIDOR_LENGTH = 24,
	CORRIDOR_WIDTH = 14,

	-- Where instances are built (ADR-007: in the zone's own server, far from the world), and the
	-- space between two instances.
	INSTANCE_ORIGIN = Vector3.new(6000, 40, 0),
	INSTANCE_SPACING = 1500,

	-- Enemies of each room: groups of { kind, count, elite } (kinds in Config/Enemies).
	ROOM_ENEMIES = table.freeze({
		Combat = table.freeze({
			table.freeze({ kind = "BanditThug", count = 2, elite = false }),
			table.freeze({ kind = "BanditArcher", count = 1, elite = false }),
		}),
		Elite = table.freeze({
			table.freeze({ kind = "BanditThug", count = 1, elite = true }),
			table.freeze({ kind = "BanditBomber", count = 1, elite = false }),
			table.freeze({ kind = "BanditThug", count = 1, elite = false }),
		}),
		MiniBoss = table.freeze({
			table.freeze({ kind = "BanditCaptain", count = 1, elite = false }),
			table.freeze({ kind = "BanditThug", count = 1, elite = false }),
		}),
		Boss = table.freeze({
			table.freeze({ kind = "BanditChief", count = 1, elite = false }),
			table.freeze({ kind = "BanditArcher", count = 2, elite = false }),
		}),
	}),

	-- Items in each chest (US-043). They are meant for 2 players and split among everyone inside
	-- (Davi: the solo dungeon accepts more players, but the loot is split).
	TREASURE_CHEST_ITEMS = 1,
	MINIBOSS_CHEST_ITEMS = 2,
	BOSS_CHEST_ITEMS = 4,
	CHEST_REACH = 12,

	-- The group dungeon of the M1 test (US-048, Davi 2026-11-05: one, to be cloned later): fixed
	-- rooms in the world, elites and bosses for a group, enemies that come back, and chests meant
	-- for 4 players. It uses the zone of its entrance.
	GROUP_LAYOUT = table.freeze({ "Start", "Elite", "Elite", "MiniBoss", "Elite", "Boss" }),
	GROUP_ROOM_ENEMIES = table.freeze({
		Elite = table.freeze({
			table.freeze({ kind = "BanditThug", count = 2, elite = true }),
			table.freeze({ kind = "BanditArcher", count = 1, elite = true }),
			table.freeze({ kind = "BanditBomber", count = 1, elite = false }),
		}),
		MiniBoss = table.freeze({
			table.freeze({ kind = "BanditCaptain", count = 1, elite = true }),
			table.freeze({ kind = "BanditThug", count = 2, elite = true }),
		}),
		Boss = table.freeze({
			table.freeze({ kind = "BanditChief", count = 1, elite = true }),
			table.freeze({ kind = "BanditArcher", count = 2, elite = true }),
		}),
	}),
	GROUP_RESPAWN_TIME = 240,
	GROUP_MINIBOSS_CHEST_ITEMS = 4,
	GROUP_BOSS_CHEST_ITEMS = 8,
	GROUP_ORIGIN = Vector3.new(-6000, 40, 0),
	GROUP_SPACING = 1500,

	-- Leaving before the end (Davi): seconds of channeling, out of combat (US-042).
	EXIT_CHANNEL_TIME = 30,

	-- An instance with nobody inside, and whose entrance is closed, is removed after this many
	-- seconds.
	EMPTY_INSTANCE_LIFETIME = 30,
})
