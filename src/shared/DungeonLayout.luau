--!strict
--[[
	DungeonLayout.luau
	The pure generator of the random solo dungeon (US-041, Dungeons tab): from a seed, the rooms in
	order. The same seed always gives the same dungeon, which helps reproduce bugs. The server's
	DungeonBuilder turns the list into rooms.
	Order (Dungeons tab): entrance, combat rooms, a random room, the mini-boss (chest), the elite
	combat and the boss (big chest and the exit portal). In the M1 the random room is always the
	treasure room; the trap and the event come later.
]]

local DungeonsConfig = require(script.Parent.Config.Dungeons)

export type RoomKind = "Start" | "Combat" | "Treasure" | "MiniBoss" | "Elite" | "Boss"
export type Layout = { seed: number, rooms: { RoomKind } }

local DungeonLayout = {}

function DungeonLayout.generate(seed: number): Layout
	local random = Random.new(seed)
	local combatRooms = random:NextInteger(DungeonsConfig.MIN_COMBAT_ROOMS, DungeonsConfig.MAX_COMBAT_ROOMS)
	local rooms: { RoomKind } = { "Start" }
	-- The last combat room is the elite one, after the mini-boss.
	for _ = 1, combatRooms - 1 do
		table.insert(rooms, "Combat")
	end
	table.insert(rooms, "Treasure")
	table.insert(rooms, "MiniBoss")
	table.insert(rooms, "Elite")
	table.insert(rooms, "Boss")
	return { seed = seed, rooms = rooms }
end

return table.freeze(DungeonLayout)
