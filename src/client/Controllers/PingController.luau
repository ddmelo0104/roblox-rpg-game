--!strict
--[[
	PingController.luau
	Client side of the network example (US-005): on join, it sends a ping and prints the server's
	answer in the Output.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes") :: ModuleScript)

local PingController = {}

function PingController:Start()
	local event = Remotes.event("RequestPing")

	event.OnClientEvent:Connect(function(value: number, serverTime: number)
		print(`[Network] ping ok · {value} · server time {string.format("%.2f", serverTime)}`)
	end)

	event:FireServer(1)
end

return PingController
