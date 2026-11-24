--!strict
--[[
	StatusService.luau
	Sets short statuses on characters and NPCs (Shared.Status). For now, the stun of a successful
	parry (US-013): Config/Combat.PARRY_STUN_TIME, decided by Davi on 2026-11-23.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Status = require(ReplicatedStorage.Shared.Status)

local StatusService = {}

-- Stuns `model` for `seconds` from now. A longer stun already running is kept.
function StatusService.stun(model: Model, seconds: number)
	local untilTime = Workspace:GetServerTimeNow() + seconds
	local current = model:GetAttribute(Status.STUNNED_UNTIL)
	if typeof(current) ~= "number" or current < untilTime then
		model:SetAttribute(Status.STUNNED_UNTIL, untilTime)
	end
end

return StatusService
