--!strict
--[[
	Project.luau
	General project info shared by the server and the client.
	Also the example of a ModuleScript in ReplicatedStorage.Shared used by both sides (US-003).
]]

local Project = {}

Project.NAME = "Projeto RPG" -- working title, until the game gets a name
Project.VERSION = "0.0.1"

-- Short text for logs, e.g. "Projeto RPG v0.0.1".
function Project.describe(): string
	return `{Project.NAME} v{Project.VERSION}`
end

return Project
