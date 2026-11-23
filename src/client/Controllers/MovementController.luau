--!strict
--[[
	MovementController.luau
	Sprinting on PC (US-010): holding the sprint key asks the server to sprint, and releasing it
	asks to stop. The speed changes right away on the client (prediction), and the server decides:
	its value is the one that counts and is replicated to the character.
	In combat, jumps are spaced out (US-015). Sprinting stays free, in or out of combat.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CombatState = require(Shared:WaitForChild("CombatState") :: ModuleScript)
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

-- In combat, after each jump the next one waits JUMP_COOLDOWN_IN_COMBAT seconds (US-015). Out of
-- combat, jumping is free.
local function limitJumpsInCombat(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end
	humanoid.StateChanged:Connect(function(_, newState)
		if newState ~= Enum.HumanoidStateType.Jumping or not CombatState.isInCombat(player) then
			return
		end
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		task.delay(MovementConfig.JUMP_COOLDOWN_IN_COMBAT, function()
			if humanoid.Parent then
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			end
		end)
	end)
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
	player.CharacterAdded:Connect(function(character)
		sprinting = false
		limitJumpsInCombat(character)
	end)
	local current = player.Character
	if current then
		task.spawn(limitJumpsInCombat, current)
	end
end

return MovementController
