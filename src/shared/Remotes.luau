--!strict
--[[
	Remotes.luau
	Single list of the game's Remotes (US-005). The server creates all of them in
	ReplicatedStorage.Remotes before starting the Services; the client only waits for them.

	Every Remote is either a client intent ("I want to sprint") or a server notice; the client never
	sends a result (ADR-002). To add a Remote: add its name to LIST and validate what arrives through
	it on the server with Network.onReceive.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"

-- All of them are RemoteEvents. Server-to-client RemoteFunctions are forbidden: the client might
-- never answer and hang the server.
local LIST: { string } = {
	"RequestPing", -- US-005: example of a validated request
	"RequestSprint", -- US-010: ask to sprint (true) or to stop (false)
	"RequestAbility", -- US-012: use an ability (id, direction and, for the target strike, the locked target)
	"AbilityUsed", -- US-012: server notice to everyone (who used which ability, from where, who was hit, damage)
}

local Remotes = {}

-- Server only: creates the folder and one RemoteEvent per name in the list.
function Remotes.create()
	assert(RunService:IsServer(), "Remotes.create only runs on the server")

	local folder: Instance
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing then
		folder = existing
	else
		local newFolder = Instance.new("Folder")
		newFolder.Name = FOLDER_NAME
		newFolder.Parent = ReplicatedStorage
		folder = newFolder
	end

	for _, name in LIST do
		if not folder:FindFirstChild(name) then
			local event = Instance.new("RemoteEvent")
			event.Name = name
			event.Parent = folder
		end
	end
end

-- Both sides: the RemoteEvent with this name. On the client, waits for it to replicate.
function Remotes.event(name: string): RemoteEvent
	assert(table.find(LIST, name), `Unknown remote: {name}`)
	local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME)
	return folder:WaitForChild(name) :: RemoteEvent
end

return table.freeze(Remotes)
