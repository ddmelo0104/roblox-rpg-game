--!strict
--[[
	TutorialController.luau
	The tutorial tracker (US-045): on the right side of the screen, the step the player is on and
	its progress ("Tutorial 3/5 · Derrote 3 bandidos (1/3)"), as the server sends it
	(TutorialUpdate). When the tutorial ends it shows the reward for a few seconds, then hides.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes") :: ModuleScript)

-- Game text (Portuguese) and visual settings.
local DONE_TEXT = "Tutorial concluído! Você ganhou: %s"
local DONE_TIME = 8
local TEXT_COLOR = Color3.fromRGB(255, 235, 170)

local TutorialController = {}

local player = Players.LocalPlayer

function TutorialController:Start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "TutorialTracker"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 2

	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(1, 0)
	label.Position = UDim2.new(1, -16, 0, 120)
	label.Size = UDim2.fromOffset(320, 60)
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.BackgroundTransparency = 0.5
	label.BorderSizePixel = 0
	label.TextColor3 = TEXT_COLOR
	label.TextSize = 15
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.GothamBold
	label.Visible = false
	label.Parent = gui
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = label

	gui.Parent = player:WaitForChild("PlayerGui")

	Remotes.event("TutorialUpdate").OnClientEvent:Connect(function(state: any)
		if state.done then
			if state.reward then
				label.Text = string.format(DONE_TEXT, state.reward)
				label.Visible = true
				task.delay(DONE_TIME, function()
					label.Visible = false
				end)
			else
				label.Visible = false
			end
			return
		end
		local progress = if state.needed > 1 then ` ({state.count}/{state.needed})` else ""
		label.Text = `Tutorial {state.index}/{state.total} · {state.text}{progress}`
		label.Visible = true
	end)
end

return TutorialController
