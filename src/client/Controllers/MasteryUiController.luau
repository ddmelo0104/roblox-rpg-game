--!strict
--[[
	MasteryUiController.luau
	Mastery screen on PC (US-032), a first take on the Progression tab's mastery tree: every line with
	its mastery level, a bar to the next level and the next tier it unlocks, and under it the items of
	the line with their specialization. Config/Interface.MASTERY_KEY opens and closes it, and opening
	it leaves combat mode so the mouse is free. The final UI belongs to EP-011.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local InterfaceConfig = require(Shared:WaitForChild("Config"):WaitForChild("Interface") :: ModuleScript)
local ItemsConfig = require(Shared:WaitForChild("Config"):WaitForChild("Items") :: ModuleScript)
local Mastery = require(Shared:WaitForChild("Mastery") :: ModuleScript)
local ProgressionConfig = require(Shared:WaitForChild("Config"):WaitForChild("Progression") :: ModuleScript)
local CameraController = require(script.Parent.CameraController)
local InventoryController = require(script.Parent.InventoryController)

-- Game text (Portuguese) and visual settings.
local TITLE = "Maestria"
local HINT = "A fama vai para o que você usa: arma 100%, peitoral 50%, elmo e botas 25%."
local PANEL_COLOR = Color3.fromRGB(20, 20, 26)
local BAR_BACK_COLOR = Color3.fromRGB(45, 45, 56)
local BAR_COLOR = Color3.fromRGB(120, 230, 255)
local ITEM_TEXT_COLOR = Color3.fromRGB(190, 190, 200)
local WIDTH = 330
local HEIGHT = 470
local PADDING = 10

type LineRow = { title: TextLabel, fill: Frame, next: TextLabel, items: { [string]: TextLabel } }

local MasteryUiController = {}

local player = Players.LocalPlayer

local function newText(parent: Instance, height: number, textSize: number, color: Color3, order: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, height)
	label.BackgroundTransparency = 1
	label.TextColor3 = color
	label.TextSize = textSize
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Text = ""
	label.LayoutOrder = order
	label.Parent = parent
	return label
end

-- The item kinds of each line, sorted by name.
local function itemsByLine(): { [string]: { string } }
	local result: { [string]: { string } } = {}
	for itemId, definition in ItemsConfig.ITEMS :: any do
		local list = result[definition.line]
		if not list then
			list = {}
			result[definition.line] = list
		end
		table.insert(list, itemId)
	end
	for _, list in result do
		table.sort(list, function(a, b)
			return (ItemsConfig.ITEMS :: any)[a].name < (ItemsConfig.ITEMS :: any)[b].name
		end)
	end
	return result
end

-- The next tier the line unlocks above `level`, and the level it needs; nil when all are unlocked.
local function nextTier(level: number): (number?, number?)
	for tier, required in ProgressionConfig.TIER_MASTERY do
		if tier <= ItemsConfig.MAX_TIER and required > level then
			return tier, required
		end
	end
	return nil, nil
end

local function createScreen(): (ScreenGui, { [string]: LineRow })
	local gui = Instance.new("ScreenGui")
	gui.Name = "MasteryScreen"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5
	gui.Enabled = false

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.Position = UDim2.new(0, 20, 0.5, 0)
	panel.Size = UDim2.fromOffset(WIDTH, HEIGHT)
	panel.BackgroundColor3 = PANEL_COLOR
	panel.BackgroundTransparency = 0.1
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(PADDING, PADDING)
	list.Size = UDim2.new(1, -2 * PADDING, 1, -2 * PADDING)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 2)
	layout.Parent = list

	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end
	newText(list, 26, 18, Color3.new(1, 1, 1), nextOrder()).Text = TITLE
	newText(list, 32, 12, ITEM_TEXT_COLOR, nextOrder()).Text = HINT

	local rows: { [string]: LineRow } = {}
	local items = itemsByLine()
	for _, line in ItemsConfig.LINES do
		local title = newText(list, 22, 15, Color3.new(1, 1, 1), nextOrder())

		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(1, -8, 0, 6)
		bar.BackgroundColor3 = BAR_BACK_COLOR
		bar.BorderSizePixel = 0
		bar.LayoutOrder = nextOrder()
		bar.Parent = list
		local fill = Instance.new("Frame")
		fill.Size = UDim2.fromScale(0, 1)
		fill.BackgroundColor3 = BAR_COLOR
		fill.BorderSizePixel = 0
		fill.Parent = bar

		local nextLabel = newText(list, 16, 12, ITEM_TEXT_COLOR, nextOrder())
		local itemLabels: { [string]: TextLabel } = {}
		for _, itemId in items[line] or {} do
			itemLabels[itemId] = newText(list, 16, 12, ITEM_TEXT_COLOR, nextOrder())
		end
		newText(list, 6, 6, ITEM_TEXT_COLOR, nextOrder())
		rows[line] = { title = title, fill = fill, next = nextLabel, items = itemLabels }
	end

	gui.Parent = player:WaitForChild("PlayerGui")
	return gui, rows
end

local function render(rows: { [string]: LineRow })
	local progress = InventoryController.progress()
	for line, row in rows do
		local fame = progress.lines[line] or 0
		local level = Mastery.level(fame)
		row.title.Text = `{Mastery.lineName(line)} · maestria {level}`
		if level >= ProgressionConfig.MAX_LEVEL then
			row.fill.Size = UDim2.fromScale(1, 1)
		else
			local from, to = Mastery.fameForLevel(level), Mastery.fameForLevel(level + 1)
			row.fill.Size = UDim2.fromScale(math.clamp((fame - from) / (to - from), 0, 1), 1)
		end
		local tier, required = nextTier(level)
		row.next.Text = if tier then `Libera T{tier} na maestria {required}` else "Todos os tiers liberados"
		for itemId, label in row.items do
			local definition = (ItemsConfig.ITEMS :: any)[itemId]
			label.Text = `    {definition.name} · especialização {Mastery.specialization(progress, itemId)}`
		end
	end
end

function MasteryUiController:Start()
	local gui, rows = createScreen()
	render(rows)
	InventoryController.changed:Connect(function()
		if gui.Enabled then
			render(rows)
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.KeyCode ~= InterfaceConfig.MASTERY_KEY then
			return
		end
		gui.Enabled = not gui.Enabled
		if gui.Enabled then
			render(rows)
			-- The mouse must be free: leave combat mode.
			CameraController.setCombatMode(false)
		end
	end)
end

return MasteryUiController
