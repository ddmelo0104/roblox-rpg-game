--!strict
--[[
	KnockdownController.luau
	The knockdown screen (US-038, US-039): while the player is down, a dark screen shows how many
	seconds until they get up (or die, where nobody gets up alone), and a button to give up. Where
	giving up counts as being finished, the screen says so: they lose everything they carry. In a
	dungeon of the Red zone it says that giving up sends them to the city (US-049). The
	prompts on the player's own character (revive and finish, for other players) stay hidden for
	them. Roblox's reset button is turned off, so nobody uses it to escape a knockdown.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Knockdown = require(Shared:WaitForChild("Knockdown") :: ModuleScript)
local Remotes = require(Shared:WaitForChild("Remotes") :: ModuleScript)

-- Game text (Portuguese) and visual settings.
local TITLE = "Derrubado"
local GET_UP_TEXT = "Você levanta em %d s. Outro jogador pode te reanimar."
local DIE_TEXT = "Você morre em %d s, a menos que alguém te reanime."
local LOSES_TEXT = "Desistir agora conta como ser finalizado: você perde o que carrega."
local TO_CITY_TEXT = "Desistir numa dungeon da Zona Vermelha te leva de volta para a cidade."
local GIVE_UP_TEXT = "Desistir"
local TITLE_COLOR = Color3.fromRGB(230, 80, 80)

type Screen = { gui: ScreenGui, text: TextLabel, warning: TextLabel }

local KnockdownController = {}

local player = Players.LocalPlayer

local function newLabel(parent: Instance, position: UDim2, textSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Size = UDim2.fromOffset(800, textSize + 10)
	label.Position = position
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.TextSize = textSize
	label.Font = Enum.Font.GothamBold
	label.Text = ""
	label.Parent = parent
	return label
end

local function createScreen(): Screen
	local gui = Instance.new("ScreenGui")
	gui.Name = "KnockdownScreen"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 8
	gui.Enabled = false

	local shade = Instance.new("Frame")
	shade.Size = UDim2.fromScale(1, 1)
	shade.BackgroundColor3 = Color3.new(0, 0, 0)
	shade.BackgroundTransparency = 0.45
	shade.Parent = gui

	local title = newLabel(gui, UDim2.fromScale(0.5, 0.35), 40)
	title.Text = TITLE
	title.TextColor3 = TITLE_COLOR
	local text = newLabel(gui, UDim2.fromScale(0.5, 0.43), 22)
	local warning = newLabel(gui, UDim2.fromScale(0.5, 0.49), 18)
	warning.TextColor3 = TITLE_COLOR

	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Size = UDim2.fromOffset(180, 44)
	button.Position = UDim2.fromScale(0.5, 0.58)
	button.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 20
	button.Font = Enum.Font.GothamBold
	button.Text = GIVE_UP_TEXT
	button.Parent = gui
	button.MouseButton1Click:Connect(function()
		Remotes.event("RequestGiveUp"):FireServer()
	end)

	gui.Parent = player:WaitForChild("PlayerGui")
	return { gui = gui, text = text, warning = warning }
end

-- The prompts on this player's own character are for other players.
local function hideOwnPrompts(character: Model)
	local function hide(instance: Instance)
		if instance:IsA("ProximityPrompt") then
			instance.Enabled = false
		end
	end
	for _, descendant in character:GetDescendants() do
		hide(descendant)
	end
	character.DescendantAdded:Connect(hide)
end

-- Turns off Roblox's reset button; the core GUI may not be ready yet, so it tries a few times.
local function disableReset()
	for _ = 1, 20 do
		local ok = pcall(function()
			StarterGui:SetCore("ResetButtonCallback", false)
		end)
		if ok then
			return
		end
		task.wait(0.5)
	end
end

function KnockdownController:Start()
	local screen = createScreen()
	task.spawn(disableReset)
	if player.Character then
		hideOwnPrompts(player.Character)
	end
	player.CharacterAdded:Connect(hideOwnPrompts)

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.1 then
			return
		end
		elapsed = 0
		local untilTime = player:GetAttribute(Knockdown.DOWNED_UNTIL)
		if typeof(untilTime) ~= "number" then
			screen.gui.Enabled = false
			return
		end
		screen.gui.Enabled = true
		local left = math.max(0, math.ceil(untilTime - Workspace:GetServerTimeNow()))
		local dies = player:GetAttribute(Knockdown.DIES_AT_END) == true
		screen.text.Text = string.format(if dies then DIE_TEXT else GET_UP_TEXT, left)
		screen.warning.Text = if player:GetAttribute(Knockdown.GIVE_UP_LOSES) == true
			then LOSES_TEXT
			elseif player:GetAttribute(Knockdown.GIVE_UP_TO_CITY) == true then TO_CITY_TEXT
			else ""
	end)
end

return KnockdownController
