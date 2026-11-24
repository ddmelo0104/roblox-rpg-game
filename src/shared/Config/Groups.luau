--!strict
--[[
	Config/Groups.luau
	The minimal group of the M1 (US-046; the Dungeons tab's proposal, adopted by the dev under
	Davi's delegation of 2026-11-23): invite, accept, leave, shared fame and loot bags. Guilds come
	in M3. The group fame formula is in Config/Progression.
]]

return table.freeze({
	-- Most players in a group (camps are for groups of 2 to 4).
	MAX_MEMBERS = 4,

	-- Seconds an invite waits for an answer.
	INVITE_TIME = 30,

	-- Group members within this distance (studs) of a kill share its fame and its loot bag.
	SHARE_RANGE = 80,
})
