--!strict
--[[
	ItemCell.luau
	One item square of the inventory and of the loot window (US-050, US-051): the item's name, its
	tier, a border and a tint in the rarity color, a durability bar, an arrow when it has more (▲) or
	less (▼) GS than what is worn in its slot, and red with a lock when the player's mastery cannot
	wear it yet. An empty square shows a dim text (the slot's name, on the equipment).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared:WaitForChild("Items") :: ModuleScript)
local ItemDetails = require(script.Parent.ItemDetails)

export type Cell = {
	button: TextButton,
	nameLabel: TextLabel,
	tierLabel: TextLabel,
	markLabel: TextLabel,
	durabilityBar: Frame,
	durabilityFill: Frame,
	stroke: UIStroke,
}

-- What a square shows: an item, or nil with `emptyText`; whether the player can wear it; and its GS
-- difference to the worn item (nil: no arrow).
export type Look = {
	record: any?,
	emptyText: string?,
	canWear: boolean?,
	difference: number?,
}

local EMPTY_COLOR = Color3.fromRGB(32, 32, 40)
local EMPTY_BORDER = Color3.fromRGB(62, 62, 74)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
local DIM_TEXT_COLOR = Color3.fromRGB(125, 125, 140)
local CANNOT_WEAR_COLOR = Color3.fromRGB(255, 115, 115)
local CANNOT_WEAR_BACKGROUND = Color3.fromRGB(72, 28, 30)
local GOOD_COLOR = Color3.fromRGB(120, 230, 120)
local BAD_COLOR = Color3.fromRGB(255, 110, 110)
local WARN_COLOR = Color3.fromRGB(255, 200, 80)
-- How much of the rarity color goes into the background.
local RARITY_TINT = 0.18

local ItemCell = {}

local function newLabel(parent: Instance, name: string, size: UDim2, position: UDim2): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.TextColor3 = TEXT_COLOR
	label.Font = Enum.Font.GothamBold
	label.TextSize = 12
	label.Text = ""
	label.Parent = parent
	return label
end

-- A new empty square of `size` pixels inside `parent`.
function ItemCell.new(parent: Instance, size: number): Cell
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(size, size)
	button.BackgroundColor3 = EMPTY_COLOR
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Text = ""
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = EMPTY_BORDER
	stroke.Parent = button

	local nameLabel = newLabel(button, "ItemName", UDim2.new(1, -8, 1, -24), UDim2.fromOffset(4, 15))
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextScaled = true
	nameLabel.TextWrapped = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 13
	limit.MinTextSize = 8
	limit.Parent = nameLabel

	local tierLabel = newLabel(button, "Tier", UDim2.fromOffset(30, 14), UDim2.fromOffset(5, 2))
	tierLabel.TextXAlignment = Enum.TextXAlignment.Left

	local markLabel = newLabel(button, "Mark", UDim2.fromOffset(30, 14), UDim2.new(1, -35, 0, 2))
	markLabel.TextSize = 13
	markLabel.TextXAlignment = Enum.TextXAlignment.Right

	local durabilityBar = Instance.new("Frame")
	durabilityBar.Name = "Durability"
	durabilityBar.Size = UDim2.new(1, -12, 0, 3)
	durabilityBar.Position = UDim2.new(0, 6, 1, -7)
	durabilityBar.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
	durabilityBar.BorderSizePixel = 0
	durabilityBar.Visible = false
	durabilityBar.Parent = button
	local durabilityFill = Instance.new("Frame")
	durabilityFill.Name = "Fill"
	durabilityFill.Size = UDim2.fromScale(1, 1)
	durabilityFill.BorderSizePixel = 0
	durabilityFill.Parent = durabilityBar

	return {
		button = button,
		nameLabel = nameLabel,
		tierLabel = tierLabel,
		markLabel = markLabel,
		durabilityBar = durabilityBar,
		durabilityFill = durabilityFill,
		stroke = stroke,
	}
end

local function durabilityColor(durability: number): Color3
	if durability <= 25 then
		return BAD_COLOR
	elseif durability <= 50 then
		return WARN_COLOR
	end
	return GOOD_COLOR
end

-- Shows `look` in the square.
function ItemCell.show(cell: Cell, look: Look)
	local record = look.record
	if not record then
		cell.button.BackgroundColor3 = EMPTY_COLOR
		cell.stroke.Color = EMPTY_BORDER
		cell.nameLabel.Text = look.emptyText or ""
		cell.nameLabel.TextColor3 = DIM_TEXT_COLOR
		cell.tierLabel.Text = ""
		cell.markLabel.Text = ""
		cell.durabilityBar.Visible = false
		return
	end
	local definition = Items.definition(record.itemId)
	local rarityColor = ItemDetails.rarityColor(record.rarity)
	local canWear = look.canWear ~= false
	cell.stroke.Color = rarityColor
	cell.button.BackgroundColor3 = if canWear
		then EMPTY_COLOR:Lerp(rarityColor, RARITY_TINT)
		else CANNOT_WEAR_BACKGROUND
	cell.nameLabel.Text = if definition then definition.name else record.itemId
	cell.nameLabel.TextColor3 = if canWear then TEXT_COLOR else CANNOT_WEAR_COLOR
	cell.tierLabel.Text = `T{record.tier}`
	cell.tierLabel.TextColor3 = rarityColor

	local difference = look.difference
	if not canWear then
		cell.markLabel.Text = "🔒"
	elseif difference and difference >= 0.5 then
		cell.markLabel.Text = "▲"
		cell.markLabel.TextColor3 = GOOD_COLOR
	elseif difference and difference <= -0.5 then
		cell.markLabel.Text = "▼"
		cell.markLabel.TextColor3 = BAD_COLOR
	else
		cell.markLabel.Text = ""
	end

	cell.durabilityBar.Visible = true
	cell.durabilityFill.Size = UDim2.fromScale(math.clamp(record.durability / 100, 0, 1), 1)
	cell.durabilityFill.BackgroundColor3 = durabilityColor(record.durability)
end

return table.freeze(ItemCell)
