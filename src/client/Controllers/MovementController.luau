--!strict
--[[
	MovementController.luau
	Sprinting on PC (US-010): holding the sprint key asks the server to sprint, and releasing it
	asks to stop. The speed changes right away on the client (prediction), and the server decides:
	its value is the one that counts and is replicated to the character.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MovementConfig = require(Shared:WaitForChild("Config"):WaitForChild("Movement") :: ModuleScript)
local Remotes = require(Shared:WaitForChild("Remotes") :: ModuleScript)

local MovementController = {}

local player = Players.LocalPlayer
local sprinting = false

local function getHumanoid(): Humanoid?
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

local function setSprinting(event: RemoteEvent, wantsToSprint: boolean)
	if sprinting == wantsToSprint then
		return
	end
	sprinting = wantsToSprint

	-- Prediction: change it on the client right away instead of waiting for the server.
	local humanoid = getHumanoid()
	if humanoid then
		humanoid.WalkSpeed = if wantsToSprint then MovementConfig.SPRINT_SPEED else MovementConfig.WALK_SPEED
	end
	event:FireServer(wantsToSprint)
end

function MovementController:Start()
	local event = Remotes.event("RequestSprint")

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == MovementConfig.SPRINT_KEY then
			setSprinting(event, true)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == MovementConfig.SPRINT_KEY then
			setSprinting(event, false)
		end
	end)

	-- The server starts every new character walking.
	player.CharacterAdded:Connect(function()
		sprinting = false
	end)
end

return MovementController
