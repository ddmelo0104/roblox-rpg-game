--!strict
--[[
	CombatState.luau
	Whether a player is in combat: for Config/Combat.COMBAT_TIME seconds after dealing or taking
	damage (TEMPO_COMBATE in the Zones and Risk tab). The server keeps it in a Player attribute
	(CombatStateService); the client reads it for the HUD and the jump limit (US-015).
]]

local Workspace = game:GetService("Workspace")

local CombatState = {}

CombatState.IN_COMBAT_UNTIL = "InCombatUntil"

-- Whether the player is in combat right now.
function CombatState.isInCombat(player: Player): boolean
	local untilTime = player:GetAttribute(CombatState.IN_COMBAT_UNTIL)
	return typeof(untilTime) == "number" and Workspace:GetServerTimeNow() < untilTime
end

return table.freeze(CombatState)
