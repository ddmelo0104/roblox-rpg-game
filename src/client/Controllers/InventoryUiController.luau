--!strict
--[[
	InventoryUiController.luau
	The inventory screen on PC (US-019, redone in US-050; Davi, 2026-11-23: "a very intuitive and
	detailed inventory"). Three columns:
	- Equipment: the four slots around the character (head on top, weapon at the side, chest in the
	  middle, boots below) with the character's GS beside them, the attributes the equipment gives
	  (health, energy, damage, resistance, cooldown) and the keys of the kit it gives.
	- Bag: "Mochila n/24", sorted by arrival, GS, type or rarity. Each square shows the tier, the
	  rarity, the durability, ▲/▼ against the worn item, and red with a lock when the mastery is too
	  low (ItemCell).
	- Details: everything about the item under the mouse (ItemDetails).
	A click on a bag item asks to equip it; a click on a worn slot asks to unequip it. The I key or
	the X closes the screen; opening it leaves combat mode so the mouse is free. It shrinks on small
	screens, leaving room on the left for the loot window (US-051).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared:WaitForChild("Items") :: ModuleScript)
local Mastery = require(Shared:WaitForChild("Mastery") :: ModuleScript)
local InterfaceConfig = require(Shared:WaitForChild("Config"):WaitForChild("Interface") :: ModuleScript)
local ItemsConfig = require(Shared:WaitForChild("Config"):WaitForChild("Items") :: ModuleScript)
local ItemCell = require(script.Parent.Parent.ItemCell)
local ItemDetails = require(script.Parent.Parent.ItemDetails)
local CameraController = require(script.Parent.CameraController)
local InventoryController = require(script.Parent.InventoryController)

-- Game text (Portuguese).
local TITLE = "Inventário"
local CLOSE_HINT = "I para fechar"
local EQUIPMENT_TITLE = "Equipamento"
local ATTRIBUTES_TITLE = "Atributos"
local KIT_TITLE = "Teclas do seu kit"
local BAG_TITLE = "Mochila"
local FULL_TEXT = "cheia"
local SORT_TEXT = "Ordenar: %s"
local HINT = "Passe o mouse num item para ver tudo sobre ele: GS, ataques, bônus, durabilidade e a maestria que pede.\n\n"
	.. "Clique num item da mochila para equipar.\nClique num item equipado para guardar na mochila."
local LEGEND = "▲ mais GS que o equipado   ▼ menos GS   🔒 falta maestria   barra embaixo: durabilidade"
local EQUIP_HINT = "Clique para equipar."
local UNEQUIP_HINT = "Clique para guardar na mochila."
-- Sort orders of the bag, as the button shows them.
local SORT_MODES = { "chegada", "GS", "tipo", "raridade" }

-- Layout, in pixels before the screen scale.
local PANEL_WIDTH = 1010
local PANEL_HEIGHT = 560
local MARGIN = 16
local HEADER = 50
local EQUIP_CELL = 76
local EQUIP_GAP = 10
local BAG_CELL = 64
local BAG_GAP = 6
local BAG_COLUMNS = 6
local LEFT_WIDTH = 3 * EQUIP_CELL + 2 * EQUIP_GAP
local BAG_WIDTH = BAG_COLUMNS * BAG_CELL + (BAG_COLUMNS - 1) * BAG_GAP
local DETAILS_WIDTH = PANEL_WIDTH - LEFT_WIDTH - BAG_WIDTH - 4 * MARGIN
-- Room kept on the left of the screen for the loot window, and above and below the panel.
local ROOM_LEFT = 460
local ROOM_HEIGHT = 100
local MIN_SCALE = 0.45

local PANEL_COLOR = Color3.fromRGB(20, 20, 26)
local BOX_COLOR = Color3.fromRGB(28, 28, 36)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
local DIM_TEXT_COLOR = Color3.fromRGB(150, 150, 165)
local BUTTON_COLOR = Color3.fromRGB(48, 48, 60)

-- Where each slot sits around the character: (column, row) in a 3 × 3 grid.
local SLOT_PLACES: { [string]: Vector2 } = {
	Head = Vector2.new(1, 0),
	Weapon = Vector2.new(0, 1),
	Chest = Vector2.new(1, 1),
	Feet = Vector2.new(1, 2),
}
local GEAR_SCORE_PLACE = Vector2.new(2, 1)

type Screen = {
	gui: ScreenGui,
	equipCells: { [string]: ItemCell.Cell },
	bagCells: { ItemCell.Cell },
	gearScore: TextLabel,
	attributes: TextLabel,
	kit: TextLabel,
	bagTitle: TextLabel,
	sortButton: TextButton,
	detailsFrame: ScrollingFrame,
	details: TextLabel,
}

local InventoryUiController = {}

local player = Players.LocalPlayer
local sortIndex = 1
-- The bag in the order shown (the squares read it at click time).
local bagView: { any } = {}
-- What is under the mouse: a function that returns the item and what a click does, or nil.
local hovered: (() -> (any?, string))? = nil

local function newText(parent: Instance, size: UDim2, position: UDim2, textSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.TextColor3 = TEXT_COLOR
	label.Font = Enum.Font.Gotham
	label.TextSize = textSize
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextWrapped = true
	label.RichText = true
	label.Text = ""
	label.Parent = parent
	return label
end

local function newTitle(parent: Instance, text: string, width: number, position: UDim2): TextLabel
	local label = newText(parent, UDim2.fromOffset(width, 20), position, 15)
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = DIM_TEXT_COLOR
	label.Text = string.upper(text)
	return label
end

local function newButton(parent: Instance, text: string, size: UDim2, position: UDim2): TextButton
	local button = Instance.new("TextButton")
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = BUTTON_COLOR
	button.BorderSizePixel = 0
	button.TextColor3 = TEXT_COLOR
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.Text = text
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button
	return button
end

-- The bag in the chosen order. Ties keep a fixed order (tier, then uid).
local function sortedBag(bag: { any }, progress: any, mode: string): { any }
	local list = table.clone(bag)
	if mode == "chegada" then
		return list
	end
	local slotOrder: { [string]: number } = {}
	for index, slot in ItemsConfig.SLOTS do
		slotOrder[slot] = index
	end
	local function kindOf(record: any): (number, string)
		local definition = Items.definition(record.itemId)
		if not definition then
			return math.huge, record.itemId
		end
		return slotOrder[definition.slot] or math.huge, definition.name
	end
	table.sort(list, function(a, b)
		if mode == "GS" then
			local gearScoreA, gearScoreB = ItemDetails.gearScore(a, progress), ItemDetails.gearScore(b, progress)
			if gearScoreA ~= gearScoreB then
				return gearScoreA > gearScoreB
			end
		elseif mode == "raridade" then
			if a.rarity ~= b.rarity then
				return a.rarity > b.rarity
			end
		elseif mode == "tipo" then
			local slotA, nameA = kindOf(a)
			local slotB, nameB = kindOf(b)
			if slotA ~= slotB then
				return slotA < slotB
			end
			if nameA ~= nameB then
				return nameA < nameB
			end
		end
		if a.tier ~= b.tier then
			return a.tier > b.tier
		end
		return a.uid < b.uid
	end)
	return list
end

local function showDetails(screen: Screen)
	local record: any? = nil
	local hint: string? = nil
	if hovered then
		record, hint = hovered()
	end
	if record then
		screen.details.Text =
			ItemDetails.describe(record, InventoryController.progress(), InventoryController.equipped(), hint)
	else
		screen.details.Text = HINT
	end
	screen.detailsFrame.CanvasPosition = Vector2.zero
end

-- Shows the details of what `under` returns while the mouse is on `button`.
local function watchHover(screen: Screen, button: GuiButton, under: () -> (any?, string))
	button.MouseEnter:Connect(function()
		hovered = under
		showDetails(screen)
	end)
	button.MouseLeave:Connect(function()
		if hovered == under then
			hovered = nil
			showDetails(screen)
		end
	end)
end

local function fit(scale: UIScale)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local viewport = camera.ViewportSize
	local byWidth = (viewport.X - ROOM_LEFT) / PANEL_WIDTH
	local byHeight = (viewport.Y - ROOM_HEIGHT) / PANEL_HEIGHT
	scale.Scale = math.clamp(math.min(byWidth, byHeight), MIN_SCALE, 1)
end

local function createScreen(): Screen
	local gui = Instance.new("ScreenGui")
	gui.Name = "InventoryScreen"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5
	gui.Enabled = false

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(1, 0.5)
	panel.Position = UDim2.new(1, -20, 0.5, 0)
	panel.Size = UDim2.fromOffset(PANEL_WIDTH, PANEL_HEIGHT)
	panel.BackgroundColor3 = PANEL_COLOR
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel = 0
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel
	local scale = Instance.new("UIScale")
	scale.Parent = panel

	-- Header.
	local title = newText(panel, UDim2.fromOffset(300, 28), UDim2.fromOffset(MARGIN, 12), 22)
	title.Font = Enum.Font.GothamBold
	title.Text = TITLE
	local closeHint = newText(panel, UDim2.fromOffset(200, 20), UDim2.new(1, -MARGIN - 44 - 200, 0, 18), 13)
	closeHint.TextColor3 = DIM_TEXT_COLOR
	closeHint.TextXAlignment = Enum.TextXAlignment.Right
	closeHint.Text = CLOSE_HINT
	local closeButton = newButton(panel, "✕", UDim2.fromOffset(34, 34), UDim2.new(1, -MARGIN - 34, 0, 10))

	-- Equipment column: the slots around the character, the attributes and the kit.
	newTitle(panel, EQUIPMENT_TITLE, LEFT_WIDTH, UDim2.fromOffset(MARGIN, HEADER))
	local dollTop = HEADER + 26
	local step = EQUIP_CELL + EQUIP_GAP
	local equipCells: { [string]: ItemCell.Cell } = {}
	for _, slot in ItemsConfig.SLOTS do
		local place = SLOT_PLACES[slot] or Vector2.zero
		local cell = ItemCell.new(panel, EQUIP_CELL)
		cell.button.Name = slot
		cell.button.Position = UDim2.fromOffset(MARGIN + place.X * step, dollTop + place.Y * step)
		equipCells[slot] = cell
	end
	local gearScoreBox = Instance.new("Frame")
	gearScoreBox.Size = UDim2.fromOffset(EQUIP_CELL, EQUIP_CELL)
	gearScoreBox.Position = UDim2.fromOffset(MARGIN + GEAR_SCORE_PLACE.X * step, dollTop + GEAR_SCORE_PLACE.Y * step)
	gearScoreBox.BackgroundColor3 = BOX_COLOR
	gearScoreBox.BorderSizePixel = 0
	gearScoreBox.Parent = panel
	local gearScoreCorner = Instance.new("UICorner")
	gearScoreCorner.CornerRadius = UDim.new(0, 6)
	gearScoreCorner.Parent = gearScoreBox
	local gearScore = newText(gearScoreBox, UDim2.fromScale(1, 1), UDim2.new(), 16)
	gearScore.TextXAlignment = Enum.TextXAlignment.Center
	gearScore.TextYAlignment = Enum.TextYAlignment.Center

	local attributesTop = dollTop + 3 * EQUIP_CELL + 2 * EQUIP_GAP + 14
	newTitle(panel, ATTRIBUTES_TITLE, LEFT_WIDTH, UDim2.fromOffset(MARGIN, attributesTop))
	local attributes =
		newText(panel, UDim2.fromOffset(LEFT_WIDTH, 64), UDim2.fromOffset(MARGIN, attributesTop + 22), 14)
	attributes.LineHeight = 1.15
	local kitTop = attributesTop + 22 + 64 + 8
	newTitle(panel, KIT_TITLE, LEFT_WIDTH, UDim2.fromOffset(MARGIN, kitTop))
	local kit = newText(
		panel,
		UDim2.fromOffset(LEFT_WIDTH, PANEL_HEIGHT - kitTop - 22 - MARGIN),
		UDim2.fromOffset(MARGIN, kitTop + 22),
		13
	)

	-- Bag column.
	local bagLeft = 2 * MARGIN + LEFT_WIDTH
	local bagTitle = newText(panel, UDim2.fromOffset(BAG_WIDTH - 170, 22), UDim2.fromOffset(bagLeft, HEADER), 15)
	bagTitle.Font = Enum.Font.GothamBold
	local sortButton =
		newButton(panel, "", UDim2.fromOffset(160, 26), UDim2.fromOffset(bagLeft + BAG_WIDTH - 160, HEADER - 4))
	sortButton.TextSize = 13
	local gridTop = HEADER + 30
	local bagCells: { ItemCell.Cell } = {}
	for index = 1, ItemsConfig.INVENTORY_SIZE do
		local column = (index - 1) % BAG_COLUMNS
		local row = math.floor((index - 1) / BAG_COLUMNS)
		local cell = ItemCell.new(panel, BAG_CELL)
		cell.button.Name = `Bag{index}`
		cell.button.Position =
			UDim2.fromOffset(bagLeft + column * (BAG_CELL + BAG_GAP), gridTop + row * (BAG_CELL + BAG_GAP))
		table.insert(bagCells, cell)
	end
	local rows = math.ceil(ItemsConfig.INVENTORY_SIZE / BAG_COLUMNS)
	local legend = newText(
		panel,
		UDim2.fromOffset(BAG_WIDTH, 40),
		UDim2.fromOffset(bagLeft, gridTop + rows * (BAG_CELL + BAG_GAP) + 4),
		12
	)
	legend.TextColor3 = DIM_TEXT_COLOR
	legend.Text = LEGEND

	-- Details column.
	local detailsFrame = Instance.new("ScrollingFrame")
	detailsFrame.Name = "Details"
	detailsFrame.Size = UDim2.fromOffset(DETAILS_WIDTH, PANEL_HEIGHT - HEADER - MARGIN)
	detailsFrame.Position = UDim2.fromOffset(bagLeft + BAG_WIDTH + MARGIN, HEADER)
	detailsFrame.BackgroundColor3 = BOX_COLOR
	detailsFrame.BorderSizePixel = 0
	detailsFrame.ScrollBarThickness = 6
	detailsFrame.CanvasSize = UDim2.new()
	detailsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	detailsFrame.Parent = panel
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = detailsFrame
	local details = newText(detailsFrame, UDim2.fromScale(1, 0), UDim2.new(), 14)
	details.AutomaticSize = Enum.AutomaticSize.Y
	details.LineHeight = 1.1

	gui.Parent = player:WaitForChild("PlayerGui")

	closeButton.MouseButton1Click:Connect(function()
		gui.Enabled = false
	end)
	fit(scale)
	local camera = Workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			fit(scale)
		end)
	end

	return {
		gui = gui,
		equipCells = equipCells,
		bagCells = bagCells,
		gearScore = gearScore,
		attributes = attributes,
		kit = kit,
		bagTitle = bagTitle,
		sortButton = sortButton,
		detailsFrame = detailsFrame,
		details = details,
	}
end

local function render(screen: Screen)
	local progress = InventoryController.progress()
	local equipped = InventoryController.equipped()
	for slot, cell in screen.equipCells do
		ItemCell.show(cell, { record = equipped[slot], emptyText = ItemsConfig.SLOT_NAMES[slot] or slot })
	end

	local bag = InventoryController.bag()
	bagView = sortedBag(bag, progress, SORT_MODES[sortIndex])
	for index, cell in screen.bagCells do
		local record = bagView[index]
		ItemCell.show(cell, {
			record = record,
			canWear = if record then (Mastery.canWear(progress, record)) else nil,
			difference = if record then ItemDetails.difference(record, progress, equipped) else nil,
		})
	end

	local stats = InventoryController.stats()
	screen.gearScore.Text = `<font size="13" color="#a5a5b4">GS</font>\n<b>{math.floor(stats.gearScore + 0.5)}</b>`
	screen.attributes.Text = ItemDetails.statsText(stats)
	screen.kit.Text = ItemDetails.kitText(equipped)
	local count = `{BAG_TITLE} {#bag}/{ItemsConfig.INVENTORY_SIZE}`
	screen.bagTitle.Text = if #bag >= ItemsConfig.INVENTORY_SIZE
		then `{count} <font color="#ff6e6e">({FULL_TEXT})</font>`
		else count
	screen.sortButton.Text = string.format(SORT_TEXT, SORT_MODES[sortIndex])
	showDetails(screen)
end

-- Clicks and the details under the mouse. The items are read at click time, so they are current.
local function connectButtons(screen: Screen)
	for slot, cell in screen.equipCells do
		cell.button.MouseButton1Click:Connect(function()
			if InventoryController.equipped()[slot] then
				InventoryController.unequip(slot)
			end
		end)
		watchHover(screen, cell.button, function()
			return InventoryController.equipped()[slot], UNEQUIP_HINT
		end)
	end
	for index, cell in screen.bagCells do
		cell.button.MouseButton1Click:Connect(function()
			local record = bagView[index]
			if record then
				InventoryController.equip(record.uid)
			end
		end)
		watchHover(screen, cell.button, function()
			return bagView[index], EQUIP_HINT
		end)
	end
	screen.sortButton.MouseButton1Click:Connect(function()
		sortIndex = sortIndex % #SORT_MODES + 1
		render(screen)
	end)
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
			hovered = nil
			render(screen)
			-- The mouse must be free to click: leave combat mode.
			CameraController.setCombatMode(false)
		end
	end)
end

return InventoryUiController
