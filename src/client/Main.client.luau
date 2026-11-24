--!strict
--[[
	Main.client.luau
	Client entry point. Waits for the shared modules to replicate and starts every Controller in
	Client.Controllers with the Loader (US-007).
	A new client system (camera, UI, effects) is just a new ModuleScript in the Controllers folder.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- On the client, wait for ReplicatedStorage to replicate before using the shared modules.
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Loader = require(Shared:WaitForChild("Loader") :: ModuleScript)
local Project = require(Shared:WaitForChild("Project") :: ModuleScript)

local folder = (script.Parent :: Instance):FindFirstChild("Controllers")
local list = table.concat(Loader.start(folder, "Main"), ", ")

print(`[Main] client ok · {Project.describe()} · {Players.LocalPlayer.Name} · controllers: {list}`)
