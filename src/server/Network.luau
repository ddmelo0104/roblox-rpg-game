--!strict
--[[
	Network.luau
	The server's network layer (US-005, ADR-002). Every Remote that arrives from the client goes
	through Network.onReceive: first the requests-per-second limit, then the content validation.
	Anything that fails is dropped with a warning in the Output, without an error.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetworkConfig = require(ReplicatedStorage.Shared.Config.Network)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

-- Checks the arguments that came from the client. Returns whether they passed and, if not, why.
export type Validator = (...any) -> (boolean, string?)

type Window = {
	startedAt: number,
	count: number,
}

local Network = {}

-- One 1-second window per player and per Remote, for the request limit.
local windows: { [Player]: { [string]: Window } } = {}

Players.PlayerRemoving:Connect(function(player)
	windows[player] = nil
end)

local function windowsOf(player: Player): { [string]: Window }
	local existing = windows[player]
	if existing then
		return existing
	end
	local created: { [string]: Window } = {}
	windows[player] = created
	return created
end

-- Counts the request and says whether it is still within the limit. Warns once per window.
local function isWithinLimit(player: Player, name: string): boolean
	local now = os.clock()
	local playerWindows = windowsOf(player)
	local window = playerWindows[name]
	if not window or now - window.startedAt >= 1 then
		playerWindows[name] = { startedAt = now, count = 1 }
		return true
	end
	window.count += 1
	local limit = NetworkConfig.MAX_REQUESTS_PER_SECOND
	if window.count == limit + 1 then
		warn(`[Network] {name}: {player.Name} exceeded {limit} requests per second`)
	end
	return window.count <= limit
end

-- Connects the Remote `name` to a server function. `validate` receives the client's arguments and
-- checks type and range; `handler` only runs if the request passes the limit and the validation.
function Network.onReceive(name: string, validate: Validator, handler: (player: Player, ...any) -> ())
	Remotes.event(name).OnServerEvent:Connect(function(player: Player, ...: any)
		if not isWithinLimit(player, name) then
			return
		end
		local ok, reason = validate(...)
		if not ok then
			warn(`[Network] {name} rejected from {player.Name}: {reason or "invalid content"}`)
			return
		end
		handler(player, ...)
	end)
end

return table.freeze(Network)
