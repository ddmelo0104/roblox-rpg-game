--!strict
--[[
	Knockdown.luau
	Where the server publishes that a player is down (EP-009), for both sides: the server's services
	(no damage, no attacks, enemies leave them alone) and the client (the knockdown screen, the
	target lock).
]]

local Knockdown = {}

-- Player attribute: the server time at which the downed player gets up (or dies, where nobody gets
-- up alone). It exists only while they are down.
Knockdown.DOWNED_UNTIL = "DownedUntil"

-- Player attribute: true while giving up would count as being finished (full loot).
Knockdown.GIVE_UP_LOSES = "GiveUpLoses"

-- Player attribute: true where the player would not get up alone (the Black zone).
Knockdown.DIES_AT_END = "DiesAtEnd"

-- Whether the player is down right now.
function Knockdown.isDowned(player: Player): boolean
	return typeof(player:GetAttribute(Knockdown.DOWNED_UNTIL)) == "number"
end

return table.freeze(Knockdown)
