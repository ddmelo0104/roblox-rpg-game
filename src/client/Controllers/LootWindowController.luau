--!strict
--[[
	LootWindowController.luau
	The loot window (US-051; Davi, 2026-11-23: take the items from chests instead of receiving them
	at once). When the player opens a chest or a loot bag, the server sends what it holds for them
	(ContainerView) and this window shows it on the left of the screen, with the same squares and
	details as the inventory (▲/▼ against the worn item, a lock when the mastery is too low). A click
	on an item asks the server to take it; "Pegar tudo" takes everything that fits in the bag. The
	window closes with the X, when nothing is left for the player, when the container goes away or
	when the player walks away; closing tells the server (RequestCloseContainer).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Mastery = require(Shared:WaitForChild("Mastery") :: ModuleScript)
local Remotes = require(Shared:WaitForChild("Remotes") :: ModuleScript)
local ItemsConfig = require(Shared:WaitForChild("Config"):WaitForChild("Items") :: ModuleScript)
local ItemCell = require(script.Parent.Parent.ItemCell)
local ItemDetails = require(script.Parent.Parent.ItemDetails)
local CameraController = require(script.Parent.CameraController)
local InventoryController = require(script.Parent.InventoryController)

-- Game text (Portuguese).
local TAKE_ALL_TEXT = "Pegar tudo"
local TAKE_HINT = "Clique para pegar."
local HINT = "Passe o mouse num item para ver os detalhes.\nClique num item para pegar, ou pegue tudo."
local BAG_TEXT = "Sua mochila: %d/%d"
local FULL_BAG_TEXT = "Sua mochila está cheia: equipe ou largue algo."

-- Layout, in pixels before the screen scale.
local WIDTH = 392
local HEIGHT = 530
local MARGIN = 14
local CELL = 64
local GAP = 6
local GRID_HEIGHT = 3 * CELL + 2 * GAP + 8
local DETAILS_HEIGHT = 190
local ROOM_HEIGHT = 100
local MIN_SCALE = 0.45
-- Studs past the container's reach before the window closes by itself.
local CLOSE_MARGIN = 6
-- Seconds between distance checks.
local CHECK_INTERVAL = 0.25

local PANEL_COLOR = Color3.fromRGB(20, 20, 26)
local BOX_COLOR = Color3.fromRGB(28, 28, 36)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
local DIM_TEXT_COLOR = Color3.fromRGB(150, 150, 165)
local BUTTON_COLOR = Color3.fromRGB(48, 48, 60)
local TAKE_ALL_COLOR = Color3.fromRGB(60, 140, 70)
local FULL_COLOR = Color3.fromRGB(255, 110, 110)

-- What the server sent: the container, where it is and the items it holds for this player.
type View = { id: string, title: string, position: Vector3, reach: number, items: { any } }

type Screen = {
	gui: ScreenGui,
	title: TextLabel,
	count: TextLabel,
	grid: ScrollingFrame,
	detailsFrame: ScrollingFrame,
	details: TextLabel,
	bagStatus: TextLabel,
	takeAll: TextButton,
}

local LootWindowController = {}

local player = Players.LocalPlayer
local screen: Screen? = nil
local current: View? = nil
local cells: { ItemCell.Cell } = {}
-- The uid of the item under the mouse.
local hoveredUid: string? = nil

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

local function newButton(parent: Instance, text: string, size: UDim2, position: UDim2, color: Color3): TextButton
	local button = Instance.new("TextButton")
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.TextColor3 = TEXT_COLOR
	button.Font = Enum.Font.GothamBold
	button.TextSize = 15
	button.Text = text
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button
	return button
end

local function newScrollingBox(parent: Instance, size: UDim2, position: UDim2): ScrollingFrame
	local frame = Instance.new("ScrollingFrame")
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = BOX_COLOR
	frame.BorderSizePixel = 0
	frame.ScrollBarThickness = 6
	frame.CanvasSize = UDim2.new()
	frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	frame.Parent = parent
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = frame
	return frame
end

local function fit(scale: UIScale)
	local camera = Workspace.CurrentCamera
	if camera then
		scale.Scale = math.clamp((camera.ViewportSize.Y - ROOM_HEIGHT) / HEIGHT, MIN_SCALE, 1)
	end
end

local function createScreen(): Screen
	local gui = Instance.new("ScreenGui")
	gui.Name = "LootWindow"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 6
	gui.Enabled = false

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.Position = UDim2.new(0, 20, 0.5, 0)
	panel.Size = UDim2.fromOffset(WIDTH, HEIGHT)
	panel.BackgroundColor3 = PANEL_COLOR
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel = 0
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel
	local scale = Instance.new("UIScale")
	scale.Parent = panel

	local title = newText(panel, UDim2.fromOffset(WIDTH - 2 * MARGIN - 40, 28), UDim2.fromOffset(MARGIN, 10), 22)
	title.Font = Enum.Font.GothamBold
	local count = newText(panel, UDim2.fromOffset(WIDTH - 2 * MARGIN - 40, 18), UDim2.fromOffset(MARGIN, 36), 13)
	count.TextColor3 = DIM_TEXT_COLOR
	local closeButton =
		newButton(panel, "✕", UDim2.fromOffset(34, 34), UDim2.new(1, -MARGIN - 34, 0, 10), BUTTON_COLOR)

	local grid = newScrollingBox(panel, UDim2.fromOffset(WIDTH - 2 * MARGIN, GRID_HEIGHT), UDim2.fromOffset(MARGIN, 62))
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(CELL, CELL)
	layout.CellPadding = UDim2.fromOffset(GAP, GAP)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid

	local detailsTop = 62 + GRID_HEIGHT + 10
	local detailsFrame = newScrollingBox(
		panel,
		UDim2.fromOffset(WIDTH - 2 * MARGIN, DETAILS_HEIGHT),
		UDim2.fromOffset(MARGIN, detailsTop)
	)
	local details = newText(detailsFrame, UDim2.fromScale(1, 0), UDim2.new(), 13)
	details.AutomaticSize = Enum.AutomaticSize.Y
	details.LineHeight = 1.1

	local bottom = detailsTop + DETAILS_HEIGHT + 12
	local bagStatus =
		newText(panel, UDim2.fromOffset(WIDTH - 2 * MARGIN - 160, 40), UDim2.fromOffset(MARGIN, bottom), 13)
	bagStatus.TextYAlignment = Enum.TextYAlignment.Center
	local takeAll = newButton(
		panel,
		TAKE_ALL_TEXT,
		UDim2.fromOffset(150, 40),
		UDim2.fromOffset(WIDTH - MARGIN - 150, bottom),
		TAKE_ALL_COLOR
	)

	gui.Parent = player:WaitForChild("PlayerGui")
	fit(scale)
	local camera = Workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			fit(scale)
		end)
	end

	closeButton.MouseButton1Click:Connect(function()
		LootWindowController.close(true)
	end)
	takeAll.MouseButton1Click:Connect(function()
		if current then
			Remotes.event("RequestTakeAll"):FireServer(current.id)
		end
	end)

	return {
		gui = gui,
		title = title,
		count = count,
		grid = grid,
		detailsFrame = detailsFrame,
		details = details,
		bagStatus = bagStatus,
		takeAll = takeAll,
	}
end

local function showDetails(target: Screen)
	local view = current
	local record: any? = nil
	if view and hoveredUid then
		for _, item in view.items do
			if item.uid == hoveredUid then
				record = item
				break
			end
		end
	end
	if record then
		target.details.Text =
			ItemDetails.describe(record, InventoryController.progress(), InventoryController.equipped(), TAKE_HINT)
	else
		target.details.Text = HINT
	end
	target.detailsFrame.CanvasPosition = Vector2.zero
end

local function showBag(target: Screen)
	local carried = #InventoryController.bag()
	if carried >= ItemsConfig.INVENTORY_SIZE then
		target.bagStatus.Text = FULL_BAG_TEXT
		target.bagStatus.TextColor3 = FULL_COLOR
	else
		target.bagStatus.Text = string.format(BAG_TEXT, carried, ItemsConfig.INVENTORY_SIZE)
		target.bagStatus.TextColor3 = DIM_TEXT_COLOR
	end
end

local function render(target: Screen, view: View)
	for _, cell in cells do
		cell.button:Destroy()
	end
	table.clear(cells)
	local progress = InventoryController.progress()
	local equipped = InventoryController.equipped()
	for index, record in view.items do
		local cell = ItemCell.new(target.grid, CELL)
		cell.button.LayoutOrder = index
		ItemCell.show(cell, {
			record = record,
			canWear = (Mastery.canWear(progress, record)),
			difference = ItemDetails.difference(record, progress, equipped),
		})
		local uid = record.uid
		cell.button.MouseEnter:Connect(function()
			hoveredUid = uid
			showDetails(target)
		end)
		cell.button.MouseLeave:Connect(function()
			if hoveredUid == uid then
				hoveredUid = nil
				showDetails(target)
			end
		end)
		cell.button.MouseButton1Click:Connect(function()
			Remotes.event("RequestTakeItem"):FireServer(view.id, uid)
		end)
		table.insert(cells, cell)
	end
	target.title.Text = view.title
	target.count.Text = if #view.items == 1 then "1 item" else `{#view.items} itens`
	showBag(target)
	showDetails(target)
end

-- Closes the window; `tellServer` when the player closed it (not when the server did).
function LootWindowController.close(tellServer: boolean)
	local view = current
	if view and tellServer then
		Remotes.event("RequestCloseContainer"):FireServer(view.id)
	end
	current = nil
	hoveredUid = nil
	if screen then
		screen.gui.Enabled = false
	end
end

-- A message from the server: what a container holds for this player, or that it closed.
local function onView(payload: any)
	local target = screen
	if not target or typeof(payload) ~= "table" or typeof(payload.id) ~= "string" then
		return
	end
	if payload.closed == true then
		if current and current.id == payload.id then
			LootWindowController.close(false)
		end
		return
	end
	if
		typeof(payload.title) ~= "string"
		or typeof(payload.position) ~= "Vector3"
		or typeof(payload.reach) ~= "number"
		or typeof(payload.items) ~= "table"
	then
		return
	end
	if current and current.id ~= payload.id then
		LootWindowController.close(true) -- another container opened: let go of the old one
	end
	local opening = current == nil
	current = {
		id = payload.id,
		title = payload.title,
		position = payload.position,
		reach = payload.reach,
		items = payload.items,
	}
	if #payload.items == 0 then
		LootWindowController.close(true) -- nothing left for this player here
		return
	end
	render(target, current :: View)
	target.gui.Enabled = true
	if opening then
		-- The mouse must be free to click: leave combat mode.
		CameraController.setCombatMode(false)
	end
end

function LootWindowController:Start()
	screen = createScreen()
	Remotes.event("ContainerView").OnClientEvent:Connect(onView)
	InventoryController.changed:Connect(function()
		local target, view = screen, current
		if target and view then
			render(target, view) -- the arrows and the bag count follow the inventory
		end
	end)

	-- Walking away closes the window.
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		local view = current
		if not view then
			return
		end
		elapsed += dt
		if elapsed < CHECK_INTERVAL then
			return
		end
		elapsed = 0
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if
			not root
			or not root:IsA("BasePart")
			or (root.Position - view.position).Magnitude > view.reach + CLOSE_MARGIN
		then
			LootWindowController.close(true)
		end
	end)
end

return LootWindowController
