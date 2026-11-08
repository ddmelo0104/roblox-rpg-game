--!strict
--[[
	MovementService.luau
	Sprint and jump (US-010, Movement tab). The client only asks to sprint or to stop; the server
	checks the request and decides the speed (ADR-002). The numbers come from Config/Movement.
	Checking the actual movement against speed hacks is US-011.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovementConfig = require(ReplicatedStorage.Shared.Config.Movement)
local Validate = require(ReplicatedStorage.Shared.Validate)
local Network = require(script.Parent.Parent.Network)

local MovementService = {}

-- What the server decided for each player. It is the reference for US-011.
local sprinting: { [Player]: boolean } = {}

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

local function allowedSpeed(player: Player): number
	if sprinting[player] then
		return MovementConfig.SPRINT_SPEED
	end
	return MovementConfig.WALK_SPEED
end

local function applySpeed(player: Player)
	local humanoid = humanoidOf(player)
	if humanoid then
		humanoid.WalkSpeed = allowedSpeed(player)
	end
end

-- Every new character starts walking, with the Config's jump.
local function setUpCharacter(player: Player, character: Model)
	sprinting[player] = false
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.UseJumpPower = false
		humanoid.JumpHeight = MovementConfig.JUMP_HEIGHT
		humanoid.WalkSpeed = MovementConfig.WALK_SPEED
	end
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		setUpCharacter(player, character)
	end)
	local current = player.Character
	if current then
		task.spawn(setUpCharacter, player, current)
	end
end

-- The speed the server allows the player right now. Used by US-011's validation.
function MovementService.allowedSpeed(player: Player): number
	return allowedSpeed(player)
end

function MovementService:Start()
	Network.onReceive("RequestSprint", Validate.boolean, function(player: Player, wantsToSprint: boolean)
		sprinting[player] = wantsToSprint
		applySpeed(player)
	end)

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		sprinting[player] = nil
	end)
end

return MovementService
