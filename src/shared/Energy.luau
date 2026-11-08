--!strict
--[[
	Energy.luau
	Where each player's energy lives (US-012). The server (EnergyService) owns the value and
	publishes it as Player attributes; the client only reads it, for the energy bar and to warn
	about missing energy before requesting an ability.
]]

local Energy = {}

Energy.ATTRIBUTE = "Energy"
Energy.MAX_ATTRIBUTE = "MaxEnergy"

-- The player's current and max energy, as published by the server (0 and 0 until it publishes).
function Energy.of(player: Player): (number, number)
	local current = player:GetAttribute(Energy.ATTRIBUTE)
	local max = player:GetAttribute(Energy.MAX_ATTRIBUTE)
	return if typeof(current) == "number" then current else 0, if typeof(max) == "number" then max else 0
end

return table.freeze(Energy)
