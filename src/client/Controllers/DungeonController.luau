--!strict
--[[
	DungeonController.luau
	Leaving a dungeon before the end (US-042): inside one, the HUD reminds the player that
	Config/Interface.DUNGEON_EXIT_KEY starts channeling out (30 s, out of combat), and while it runs
	it shows the seconds left; the same key cancels it. The server checks everything
	(RequestDungeonExit) and publishes the state as player attributes.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local InterfaceConfig = require(Shared:WaitForChild("Config"):WaitForChild("Interface") :: ModuleScript)
local Remotes = require(Shared:WaitForChild("Remotes") :: ModuleScript)

-- The attributes DungeonService sets.
local IN_DUNGEON_ATTRIBUTE = "InDungeon"
local EXIT_AT_ATTRIBUTE = "DungeonExitAt"

-- Game text (Portuguese).
local HINT_TEXT = "%s: sair da dungeon (30 s, fora de combate)"
local CHANNEL_TEXT = "Saindo da dungeon em %d s (%s cancela)"

local DungeonController = {}

local player = Players.LocalPlayer

local function createLabel(): TextLabel
	local gui = Instance.new("ScreenGui")
	gui.Name = "DungeonHud"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 3
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Size = UDim2.fromOffset(600, 24)
	label.Position = UDim2.new(0.5, 0, 1, -150)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(210, 180, 255)
	label.TextStrokeTransparency = 0.4
	label.TextSize = 16
	label.Font = Enum.Font.GothamBold
	label.Text = ""
	label.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	return label
end

function DungeonController:Start()
	local label = createLabel()
	local keyName = InterfaceConfig.DUNGEON_EXIT_KEY.Name

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.KeyCode ~= InterfaceConfig.DUNGEON_EXIT_KEY then
			return
		end
		if player:GetAttribute(IN_DUNGEON_ATTRIBUTE) ~= true then
			return
		end
		local channeling = typeof(player:GetAttribute(EXIT_AT_ATTRIBUTE)) == "number"
		Remotes.event("RequestDungeonExit"):FireServer(not channeling)
	end)

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.2 then
			return
		end
		elapsed = 0
		if player:GetAttribute(IN_DUNGEON_ATTRIBUTE) ~= true then
			label.Text = ""
			return
		end
		local exitAt = player:GetAttribute(EXIT_AT_ATTRIBUTE)
		if typeof(exitAt) == "number" then
			local left = math.max(0, math.ceil(exitAt - Workspace:GetServerTimeNow()))
			label.Text = string.format(CHANNEL_TEXT, left, keyName)
		else
			label.Text = string.format(HINT_TEXT, keyName)
		end
	end)
end

return DungeonController
