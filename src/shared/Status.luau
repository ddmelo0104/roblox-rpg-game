--!strict
--[[
	Status.luau
	Short statuses of characters and NPCs, kept in attributes so every client can show them. The
	server sets them (StatusService); both sides read them here.
	- Stun (US-013): a stunned character or NPC cannot attack.
]]

local Workspace = game:GetService("Workspace")

local Status = {}

Status.STUNNED_UNTIL = "StunnedUntil"

-- Whether `model` is stunned right now.
function Status.isStunned(model: Instance): boolean
	local untilTime = model:GetAttribute(Status.STUNNED_UNTIL)
	return typeof(untilTime) == "number" and Workspace:GetServerTimeNow() < untilTime
end

return table.freeze(Status)
