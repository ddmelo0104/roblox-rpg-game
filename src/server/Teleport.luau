--!strict
--[[
	Teleport.luau
	Moves a player far inside the place (into or out of a dungeon, US-042 and US-048): it asks
	Roblox to stream the area in first, tells ZoneService so the border rule does not pull the
	player back, and goes through the movement validation so it does not count as a cheat.
]]

local MovementValidationService = require(script.Parent.Services.MovementValidationService)
local ZoneService = require(script.Parent.Services.ZoneService)

local Teleport = {}

-- Yields while the area streams in (at most a few seconds).
function Teleport.move(player: Player, cframe: CFrame)
	ZoneService.forget(player)
	pcall(function()
		player:RequestStreamAroundAsync(cframe.Position, 5)
	end)
	MovementValidationService.teleport(player, cframe)
end

return table.freeze(Teleport)
