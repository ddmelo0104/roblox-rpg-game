--!strict
--[[
	GroupController.luau
	The group on screen (US-046): on the left, the members with their health and a button to leave;
	in the middle, a received invite with Accept and Decline, until it expires. The server sends
	the group and the invite (GroupUpdate) and decides everything (RequestGroupAnswer,
	RequestGroupLeave). Inviting is the prompt on other players' characters.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes") :: ModuleScript)

-- Game text (Portuguese) and visual settings.
local TITLE = "Grupo"
local LEAVE_TEXT = "Sair do grupo"
local INVITE_TEXT = "%s te convidou para um grupo"
local ACCEPT_TEXT = "Aceitar"
local DECLINE_TEXT = "Recusar"
local PANEL_COLOR = Color3.fromRGB(20, 20, 26)
local BAR_COLOR = Color3.fromRGB(90, 200, 90)
local ROW_HEIGHT = 30

type Row = { frame: Frame, name: TextLabel, fill: Frame, userId: number }

local GroupController = {}

local player = Players.LocalPlayer

local function newText(parent: Instance, text: string, size: number): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = size
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	label.Parent = parent
	return label
end

local function newButton(parent: Instance, text: string, width: number): TextButton
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(width, 28)
	button.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 14
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.Parent = parent
	return button
end

function GroupController:Start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "GroupHud"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 4

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.Position = UDim2.new(0, 16, 0.45, 0)
	panel.Size = UDim2.fromOffset(200, 60)
	panel.BackgroundColor3 = PANEL_COLOR
	panel.BackgroundTransparency = 0.3
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = gui
	local title = newText(panel, TITLE, 15)
	title.Position = UDim2.fromOffset(8, 4)
	title.Size = UDim2.new(1, -16, 0, 20)
	local leave = newButton(panel, LEAVE_TEXT, 184)
	leave.Position = UDim2.new(0, 8, 1, -34)
	leave.MouseButton1Click:Connect(function()
		Remotes.event("RequestGroupLeave"):FireServer()
	end)

	local invite = Instance.new("Frame")
	invite.AnchorPoint = Vector2.new(0.5, 0)
	invite.Position = UDim2.new(0.5, 0, 0, 100)
	invite.Size = UDim2.fromOffset(360, 80)
	invite.BackgroundColor3 = PANEL_COLOR
	invite.BackgroundTransparency = 0.2
	invite.BorderSizePixel = 0
	invite.Visible = false
	invite.Parent = gui
	local inviteText = newText(invite, "", 15)
	inviteText.Position = UDim2.fromOffset(10, 8)
	inviteText.Size = UDim2.new(1, -20, 0, 24)
	inviteText.TextXAlignment = Enum.TextXAlignment.Center
	local accept = newButton(invite, ACCEPT_TEXT, 120)
	accept.Position = UDim2.new(0.5, -126, 1, -38)
	local decline = newButton(invite, DECLINE_TEXT, 120)
	decline.Position = UDim2.new(0.5, 6, 1, -38)
	accept.MouseButton1Click:Connect(function()
		invite.Visible = false
		Remotes.event("RequestGroupAnswer"):FireServer(true)
	end)
	decline.MouseButton1Click:Connect(function()
		invite.Visible = false
		Remotes.event("RequestGroupAnswer"):FireServer(false)
	end)

	gui.Parent = player:WaitForChild("PlayerGui")

	local rows: { Row } = {}
	local inviteToken = 0

	Remotes.event("GroupUpdate").OnClientEvent:Connect(function(state: any)
		for _, row in rows do
			row.frame:Destroy()
		end
		table.clear(rows)
		for index, member in state.members do
			local frame = Instance.new("Frame")
			frame.Position = UDim2.fromOffset(8, 26 + (index - 1) * ROW_HEIGHT)
			frame.Size = UDim2.new(1, -16, 0, ROW_HEIGHT - 4)
			frame.BackgroundTransparency = 1
			frame.Parent = panel
			local name = newText(frame, member.name, 13)
			name.Size = UDim2.new(1, 0, 0, 14)
			local back = Instance.new("Frame")
			back.Position = UDim2.fromOffset(0, 16)
			back.Size = UDim2.new(1, 0, 0, 6)
			back.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
			back.BorderSizePixel = 0
			back.Parent = frame
			local fill = Instance.new("Frame")
			fill.Size = UDim2.fromScale(1, 1)
			fill.BackgroundColor3 = BAR_COLOR
			fill.BorderSizePixel = 0
			fill.Parent = back
			table.insert(rows, { frame = frame, name = name, fill = fill, userId = member.userId })
		end
		panel.Size = UDim2.fromOffset(200, 26 + #rows * ROW_HEIGHT + 40)
		panel.Visible = #rows > 0

		if state.inviteFrom then
			inviteToken += 1
			local token = inviteToken
			inviteText.Text = string.format(INVITE_TEXT, state.inviteFrom)
			invite.Visible = true
			task.delay(state.inviteTime, function()
				if inviteToken == token then
					invite.Visible = false
				end
			end)
		end
	end)

	-- The members' health, a few times a second.
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.2 or #rows == 0 then
			return
		end
		elapsed = 0
		for _, row in rows do
			local member = Players:GetPlayerByUserId(row.userId)
			local character = if member then member.Character else nil
			local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
			local fraction = if humanoid and humanoid.MaxHealth > 0 then humanoid.Health / humanoid.MaxHealth else 0
			row.fill.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
		end
	end)
end

return GroupController
