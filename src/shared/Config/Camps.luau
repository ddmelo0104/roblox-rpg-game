--!strict
--[[
	Config/Camps.luau
	Open-world camps for groups of 2 to 4 (US-047, Davi 2026-11-04: fixed on the map). A camp is a
	set of enemies that come back together; clearing it leaves a chest for the players who fought
	there. Numbers decided by the dev under Davi's delegation (2026-11-23).
]]

return table.freeze({
	-- Items in the chest of a cleared camp, split among its fighters nearby.
	CHEST_ITEMS = 3,
	-- Seconds the chest waits to be opened, and seconds after the camp was cleared until it comes
	-- back.
	CHEST_LIFETIME = 120,
	RESPAWN_TIME = 150,
	-- Fighters within this distance (studs) of the chest share it.
	SHARE_RANGE = 60,

	-- The test camps (if the place has no camp): studs to the left of the spawn and to its back
	-- (negative is to its front), in the Yellow and Red test zones, with these enemies.
	TEST_CAMPS = table.freeze({
		table.freeze({ left = 530, back = -150 }),
		table.freeze({ left = 790, back = -150 }),
	}),
	TEST_ENEMIES = table.freeze({
		table.freeze({ kind = "BanditThug", count = 2, elite = true }),
		table.freeze({ kind = "BanditArcher", count = 1, elite = true }),
		table.freeze({ kind = "BanditBomber", count = 1, elite = false }),
	}),
})
