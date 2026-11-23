--!strict
--[[
	InventoryUiController.luau
	Inventory screen on PC (US-019): the four equipped slots and the GS on top, the bag below, and the
	details of the item under the mouse at the bottom. A click on a bag item asks to equip it; a click
	on an equipped slot asks to unequip it. Config/Interface.INVENTORY_KEY opens and closes it, and
	opening it leaves combat mode so the mouse is free. The final UI belongs to EP-011.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared:WaitForChild("Items") :: ModuleScript)
local InterfaceConfig = require(Shared:WaitForChild("Config"):WaitForChild("Interface") :: ModuleScript)
local ItemsConfig = require(Shared:WaitForChild("Config"):WaitForChild("Items") :: ModuleScript)
local CameraController = require(script.Parent.CameraController)
local InventoryController = require(script.Parent.InventoryController)

-- Game text (Portuguese) and visual settings.
local TITLE = "Inventário"
local HINT = "Clique num item da mochila para equipar, ou num slot para tirar."
local EMPTY_SLOT_COLOR = Color3.fromRGB(70, 70, 80)
local PANEL_COLOR = Color3.fromRGB(20, 20, 26)
local SLOT_COLOR = Color3.fromRGB(35, 35, 44)
local BONUS_NAMES = {
	damage = "Dano",
	health = "Vida",
	resistance = "Resistência",
	cooldownReduction = "Recarga",
}
local CELL = 60
local GAP = 6
local COLUMNS = 6

type Screen = {
	gui: ScreenGui,
	gearScore: TextLabel,
	details: TextLabel,
	equipButtons: { [string]: TextButton },
	bagButtons: { TextButton },
}

local InventoryUiController = {}

local player = Players.LocalPlayer

local function newButton(parent: Instance, size: UDim2): TextButton
	local button = Instance.new("TextButton")
	button.Size = size
	button.BackgroundColor3 = SLOT_COLOR
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextScaled = true
	button.TextWrapped = true
	button.Text = ""
	button.Parent = parent
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 13
	limit.Parent = button
	local stroke = Instance.new("UIStroke")
	stroke.Name = "Rarity"
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = EMPTY_SLOT_COLOR
	stroke.Parent = button
	return button
end

local function newText(parent: Instance, size: UDim2, position: UDim2, textSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = textSize
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextWrapped = true
	label.Text = ""
	label.Parent = parent
	return label
end

-- What the player reads about an item under the mouse.
local function describe(record: any): string
	local lines = { Items.displayName(record), `GS {math.floor(Items.itemGearScore(record) + 0.5)}` }
	local definition = Items.definition(record.itemId)
	local bonuses = if definition and definition.armorType then ItemsConfig.ARMOR_BONUSES[definition.armorType] else nil
	if bonuses then
		local parts = {}
		for key, name in BONUS_NAMES do
			local value = bonuses[key]
			if value and value > 0 then
				local sign = if key == "cooldownReduction" then "−" else "+"
				table.insert(parts, `{name} {sign}{math.floor(value * 100 + 0.5)}%`)
			end
		end
		table.sort(parts)
		table.insert(lines, `Por peça: {table.concat(parts, " · ")}`)
	end
	table.insert(lines, `Durabilidade {math.floor(record.durability)}%`)
	return table.concat(lines, "\n")
end

local function showRecord(button: TextButton, record: any?, emptyText: string)
	local stroke = button:FindFirstChild("Rarity") :: UIStroke
	if record then
		local definition = Items.definition(record.itemId)
		button.Text = `{if definition then definition.name else record.itemId}\nT{record.tier}`
		stroke.Color = InterfaceConfig.RARITY_COLORS[record.rarity] or EMPTY_SLOT_COLOR
	else
		button.Text = emptyText
		stroke.Color = EMPTY_SLOT_COLOR
	end
end

local function createScreen(): Screen
	local gui = Instance.new("ScreenGui")
	gui.Name = "InventoryScreen"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5
	gui.Enabled = false

	local rows = math.ceil(ItemsConfig.INVENTORY_SIZE / COLUMNS)
	local width = COLUMNS * CELL + (COLUMNS + 1) * GAP
	local equipTop = 34
	local bagTop = equipTop + CELL + 24
	local height = bagTop + rows * (CELL + GAP) + 70

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(1, 0.5)
	panel.Position = UDim2.new(1, -20, 0.5, 0)
	panel.Size = UDim2.fromOffset(width, height)
	panel.BackgroundColor3 = PANEL_COLOR
	panel.BackgroundTransparency = 0.1
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local title = newText(panel, UDim2.fromOffset(width / 2, 24), UDim2.fromOffset(GAP, 6), 18)
	title.Text = TITLE
	local gearScore = newText(panel, UDim2.fromOffset(width / 2 - GAP, 24), UDim2.fromOffset(width / 2, 8), 16)
	gearScore.TextXAlignment = Enum.TextXAlignment.Right

	-- The four equipped slots, in the order of Config/Items.SLOTS.
	local equipButtons: { [string]: TextButton } = {}
	for index, slot in ItemsConfig.SLOTS do
		local button = newButton(panel, UDim2.fromOffset(CELL, CELL))
		button.Name = slot
		button.Position = UDim2.fromOffset(GAP + (index - 1) * (CELL + GAP), equipTop)
		equipButtons[slot] = button
	end

	local bagLabel = newText(panel, UDim2.fromOffset(width, 18), UDim2.fromOffset(GAP, bagTop - 20), 14)
	bagLabel.Text = `Mochila ({ItemsConfig.INVENTORY_SIZE})`

	local bagButtons: { TextButton } = {}
	for index = 1, ItemsConfig.INVENTORY_SIZE do
		local column = (index - 1) % COLUMNS
		local row = math.floor((index - 1) / COLUMNS)
		local button = newButton(panel, UDim2.fromOffset(CELL, CELL))
		button.Name = `Bag{index}`
		button.Position = UDim2.fromOffset(GAP + column * (CELL + GAP), bagTop + row * (CELL + GAP))
		table.insert(bagButtons, button)
	end

	local details = newText(panel, UDim2.fromOffset(width - 2 * GAP, 62), UDim2.new(0, GAP, 1, -66), 13)
	details.Text = HINT

	gui.Parent = player:WaitForChild("PlayerGui")
	return {
		gui = gui,
		gearScore = gearScore,
		details = details,
		equipButtons = equipButtons,
		bagButtons = bagButtons,
	}
end

local function render(screen: Screen)
	local equipped = InventoryController.equipped()
	for slot, button in screen.equipButtons do
		showRecord(button, equipped[slot], ItemsConfig.SLOT_NAMES[slot] or slot)
	end
	local bag = InventoryController.bag()
	for index, button in screen.bagButtons do
		showRecord(button, bag[index], "")
	end
	screen.gearScore.Text = `GS {math.floor(InventoryController.stats().gearScore + 0.5)}`
end

-- Clicks and the details under the mouse. The records are read at click time, so they are current.
local function connectButtons(screen: Screen)
	for slot, button in screen.equipButtons do
		button.MouseButton1Click:Connect(function()
			if InventoryController.equipped()[slot] then
				InventoryController.unequip(slot)
			end
		end)
		button.MouseEnter:Connect(function()
			local record = InventoryController.equipped()[slot]
			screen.details.Text = if record then describe(record) else HINT
		end)
		button.MouseLeave:Connect(function()
			screen.details.Text = HINT
		end)
	end
	for index, button in screen.bagButtons do
		button.MouseButton1Click:Connect(function()
			local record = InventoryController.bag()[index]
			if record then
				InventoryController.equip(record.uid)
			end
		end)
		button.MouseEnter:Connect(function()
			local record = InventoryController.bag()[index]
			screen.details.Text = if record then describe(record) else HINT
		end)
		button.MouseLeave:Connect(function()
			screen.details.Text = HINT
		end)
	end
end

function InventoryUiController:Start()
	local screen = createScreen()
	connectButtons(screen)
	render(screen)
	InventoryController.changed:Connect(function()
		render(screen)
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.KeyCode ~= InterfaceConfig.INVENTORY_KEY then
			return
		end
		screen.gui.Enabled = not screen.gui.Enabled
		if screen.gui.Enabled then
			-- The mouse must be free to click: leave combat mode.
			CameraController.setCombatMode(false)
		end
	end)
end

return InventoryUiController
