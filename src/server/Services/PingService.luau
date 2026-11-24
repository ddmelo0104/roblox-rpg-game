--!strict
--[[
	PingService.luau
	Example of the network pattern (US-005): the client asks for a ping with a number, and the
	server checks the request and answers with the same number and the server time. It is the model
	for every new Remote: declare it in Shared.Remotes, validate it here with Network.onReceive, then
	answer or act.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local NetworkConfig = require(ReplicatedStorage.Shared.Config.Network)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Validate = require(ReplicatedStorage.Shared.Validate)
local Network = require(script.Parent.Parent.Network)

local PingService = {}

function PingService:Start()
	local event = Remotes.event("RequestPing")

	Network.onReceive("RequestPing", function(value)
		return Validate.number(value, -NetworkConfig.PING_MAX_VALUE, NetworkConfig.PING_MAX_VALUE)
	end, function(player, value)
		event:FireClient(player, value, Workspace:GetServerTimeNow())
	end)
end

return PingService
