--!strict
--[[
	CombatStateService.luau
	Marks players as in combat (US-015): for Config/Combat.COMBAT_TIME seconds after they deal or take
	damage, as the Zones and Risk tab defines TEMPO_COMBATE. The state lives in a Player attribute
	(Shared.CombatState): the client reads it for the HUD and the jump limit, and the zones will use it
	to block zone changes and safe logout (EP-007, EP-009).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CombatConfig = require(ReplicatedStorage.Shared.Config.Combat)
local CombatState = require(ReplicatedStorage.Shared.CombatState)

local CombatStateService = {}

-- Puts the player in combat for COMBAT_TIME seconds from now.
function CombatStateService.mark(player: Player)
	player:SetAttribute(CombatState.IN_COMBAT_UNTIL, Workspace:GetServerTimeNow() + CombatConfig.COMBAT_TIME)
end

return CombatStateService
