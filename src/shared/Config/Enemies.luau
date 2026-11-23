--!strict
--[[
	Config/Enemies.luau
	Enemies of EP-008 (US-025 to US-028): how the AI behaves, the kinds of enemy with their numbers
	before the tier scaling, the elite multipliers and the test area. Shared.Enemies scales the
	numbers by the zone's tier; the item chance per kill lives in Config/Loot. Every number is
	provisional, decided by the dev under Davi's delegation (2026-11-23), to tune while playing.

	Fields of each kind:
	- name: shown above the enemy (Portuguese); faction: the group it belongs to (Dungeons tab)
	- attack: "Melee" (the dodge and the parry work) or "Ranged" (only the dodge works)
	- health, damage: before the tier scaling
	- range: attack reach (studs); windup: seconds of the visible warning before the hit;
	  interval: seconds between the starts of two attacks
	- speed: walk speed (studs/s); aggroRange: how close a living player must be to be noticed
	- deathBlast (optional, US-028): after dying it explodes: radius (studs), damage, delay (s)
	- rank (optional, US-043): "MiniBoss" or "Boss", for the fame (Config/Progression)
	- scale (optional): body size, 1 by default (an elite is ELITE.scale times bigger still)
	- color: body color (visual only)
]]

-- Kind id -> its numbers. Typed with a string key, so Shared.Enemies can look a kind up by id.
local KINDS: { [string]: any } = {
	BanditThug = table.freeze({
		name = "Bandido",
		faction = "Bandits",
		attack = "Melee",
		health = 450,
		damage = 10,
		range = 6,
		windup = 0.7,
		interval = 2.2,
		speed = 14,
		aggroRange = 30,
		color = Color3.fromRGB(150, 75, 60),
	}),
	BanditArcher = table.freeze({
		name = "Bandido arqueiro",
		faction = "Bandits",
		attack = "Ranged",
		health = 300,
		damage = 8,
		range = 35,
		windup = 1,
		interval = 2.8,
		speed = 12,
		aggroRange = 40,
		color = Color3.fromRGB(90, 120, 70),
	}),
	BanditBomber = table.freeze({
		name = "Bandido com pólvora",
		faction = "Bandits",
		attack = "Melee",
		health = 250,
		damage = 6,
		range = 6,
		windup = 0.7,
		interval = 2.4,
		speed = 15,
		aggroRange = 30,
		deathBlast = table.freeze({ radius = 10, damage = 25, delay = 1.2 }),
		color = Color3.fromRGB(70, 60, 60),
	}),
	-- Dungeon bosses (US-043).
	BanditCaptain = table.freeze({
		name = "Capitão dos bandidos",
		faction = "Bandits",
		attack = "Melee",
		health = 2400,
		damage = 16,
		range = 7,
		windup = 0.8,
		interval = 2.4,
		speed = 14,
		aggroRange = 35,
		rank = "MiniBoss",
		scale = 1.5,
		color = Color3.fromRGB(120, 40, 40),
	}),
	BanditChief = table.freeze({
		name = "Chefe dos bandidos",
		faction = "Bandits",
		attack = "Melee",
		health = 6000,
		damage = 22,
		range = 8,
		windup = 1,
		interval = 2.6,
		speed = 13,
		aggroRange = 45,
		rank = "Boss",
		scale = 2,
		color = Color3.fromRGB(80, 20, 20),
	}),
}

return table.freeze({
	KINDS = table.freeze(KINDS),

	-- Elites (Progression tab: elite fame ×3): more health and damage, a bigger body.
	ELITE = table.freeze({ health = 3, damage = 1.5, scale = 1.25 }),

	-- AI (US-025): seconds between two decisions of an awake enemy, and between two checks of a
	-- sleeping one. An enemy sleeps (stops deciding) with no living player within SLEEP_RANGE studs.
	THINK_INTERVAL = 0.2,
	SLEEP_CHECK_INTERVAL = 1,
	SLEEP_RANGE = 150,

	-- It gives up and goes home when its target is farther than LEASH_RANGE studs from home, or when
	-- it tries to walk but moves less than STUCK_PROGRESS studs in STUCK_TIME seconds (stuck on the
	-- terrain). Going home it is not a target; at home it heals fully and forgets the damage it took.
	-- It is put back home if it takes longer than RETURN_TIMEOUT seconds.
	LEASH_RANGE = 60,
	STUCK_TIME = 4,
	STUCK_PROGRESS = 2,
	RETURN_TIMEOUT = 8,

	-- A ranged enemy stops walking when its target is within this fraction of its range, in sight.
	RANGED_STOP_FRACTION = 0.8,

	-- Seconds before an open-world enemy comes back at its spawn point (dungeon enemies never come
	-- back, Dungeons tab), and seconds its body stays on the ground.
	RESPAWN_TIME = 45,
	CORPSE_TIME = 3,

	-- Test groups (US-027): if the place has no spawn point, groups of enemies appear in a row to the
	-- left of the spawn (`left` studs), far enough apart to fight one group at a time. They take the
	-- tier and kind of the test zone they stand in (Config/Zones.TEST_LAYOUT): Blue T1 up to 250
	-- studs, the city up to 400, Yellow T2 up to 650 and Red T3 up to 950.
	TEST_AREA = table.freeze({
		ahead = 30,
		radius = 4,
		groups = table.freeze({
			table.freeze({ kind = "BanditThug", count = 2, elite = false, left = 60 }),
			table.freeze({ kind = "BanditArcher", count = 1, elite = false, left = 110 }),
			table.freeze({ kind = "BanditBomber", count = 1, elite = false, left = 160 }),
			table.freeze({ kind = "BanditThug", count = 1, elite = true, left = 210 }),
			table.freeze({ kind = "BanditThug", count = 2, elite = false, left = 480 }),
			table.freeze({ kind = "BanditArcher", count = 1, elite = false, left = 570 }),
			table.freeze({ kind = "BanditThug", count = 2, elite = false, left = 720 }),
			table.freeze({ kind = "BanditBomber", count = 1, elite = false, left = 800 }),
			table.freeze({ kind = "BanditThug", count = 1, elite = true, left = 880 }),
		}),
	}),
})
