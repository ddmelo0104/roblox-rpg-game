--!strict
--[[
	Main.server.luau
	Server entry point. Creates the project's Remotes (US-005) and starts every Service in
	ServerScriptService.Server.Services with the Loader (US-007).
	A new server system is just a new ModuleScript in the Services folder.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Loader = require(Shared.Loader)
local Project = require(Shared.Project)
local Remotes = require(Shared.Remotes)

-- The Remotes exist before any Service starts listening.
Remotes.create()

local folder = (script.Parent :: Instance):FindFirstChild("Services")
local services = Loader.start(folder, "Main")

print(`[Main] server ok · {Project.describe()} · services: {table.concat(services, ", ")}`)
