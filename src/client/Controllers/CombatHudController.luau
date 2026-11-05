--!strict
--[[
	CombatHudController.luau
	Minimal prototype HUD (US-012): the energy bar, one slot per ability with its key, name and
	cooldown, and the last notice ("sem energia", "em recarga"…). A slot's border turns red when
	there is not enough energy for the ability. The real UI belongs to EP-011.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Energy = require(Shared:WaitForChild("Energy") :: ModuleScript)
local CombatController = require(script.Parent.CombatController)
local LongswordConfig = require(Shared:WaitForChild("Config"):WaitForChild("Longsword") :: ModuleScript)

-- Visual only: sizes (in pixels), how long a notice stays on screen, and colors.
local SLOT_SIZE = 64
local GAP = 8
local ENERGY_BAR_HEIGHT = 14
local NOTICE_DURATION = 1.5
local BACKGROUND_COLOR = Color3.fromRGB(25, 25, 30)
local ENERGY_COLOR = Color3.fromRGB(80, 170, 255)
local NO_ENERGY_COLOR = Color3.fromRGB(220, 70, 70)
local NOTICE_COLOR = Color3.fromRGB(255, 200, 120)

type Slot = {
	id: string,
	cooldown: number,
	energyCost: number,
	shade: Frame,
	timer: TextLabel,
	border: UIStroke,
}

type Hud = {
	energyFill: Frame,
	energyText: TextLabel,
	notice: TextLabel,
	slots: { Slot },
}

local CombatHudController = {}

local player = Players.LocalPlayer

local function newLabel(name: string, textSize: number, parent: Instance): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = textSize
	label.Text = ""
	label.Parent = parent
	return label
end

local function newSlot(ability: any, index: number, parent: Instance): Slot
	local frame = Instance.new("Frame")
	frame.Name = ability.id
	frame.Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE)
	frame.Position = UDim2.fromOffset((index - 1) * (SLOT_SIZE + GAP), ENERGY_BAR_HEIGHT + GAP)
	frame.BackgroundColor3 = BACKGROUND_COLOR
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local border = Instance.new("UIStroke")
	border.Thickness = 2
	border.Color = BACKGROUND_COLOR
	border.Parent = frame

	local key = newLabel("Key", 14, frame)
	key.Text = ability.key.Name
	key.TextXAlignment = Enum.TextXAlignment.Left
	key.Size = UDim2.fromOffset(24, 18)
	key.Position = UDim2.fromOffset(4, 2)

	local name = newLabel("AbilityName", 11, frame)
	name.Text = ability.name
	name.TextWrapped = true
	name.Size = UDim2.new(1, -4, 0, 28)
	name.Position = UDim2.new(0, 2, 1, -30)

	-- The shade covers the slot and shrinks as the cooldown runs out.
	local shade = Instance.new("Frame")
	shade.Name = "Cooldown"
	shade.AnchorPoint = Vector2.new(0, 1)
	shade.Position = UDim2.fromScale(0, 1)
	shade.Size = UDim2.fromScale(1, 0)
	shade.BackgroundColor3 = Color3.new(0, 0, 0)
	shade.BackgroundTransparency = 0.35
	shade.BorderSizePixel = 0
	shade.ZIndex = 2
	shade.Parent = frame

	local timer = newLabel("Timer", 20, frame)
	timer.Size = UDim2.fromScale(1, 1)
	timer.ZIndex = 3

	return {
		id = ability.id,
		cooldown = ability.cooldown,
		energyCost = ability.energyCost,
		shade = shade,
		timer = timer,
		border = border,
	}
end

local function createHud(): Hud
	local gui = Instance.new("ScreenGui")
	gui.Name = "CombatHud"
	gui.ResetOnSpawn = false

	local count = #LongswordConfig
	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -20)
	bar.Size = UDim2.fromOffset(count * SLOT_SIZE + (count - 1) * GAP, ENERGY_BAR_HEIGHT + GAP + SLOT_SIZE)
	bar.BackgroundTransparency = 1
	bar.Parent = gui

	local energyBackground = Instance.new("Frame")
	energyBackground.Name = "Energy"
	energyBackground.Size = UDim2.new(1, 0, 0, ENERGY_BAR_HEIGHT)
	energyBackground.BackgroundColor3 = BACKGROUND_COLOR
	energyBackground.BorderSizePixel = 0
	energyBackground.Parent = bar

	local energyFill = Instance.new("Frame")
	energyFill.Name = "Fill"
	energyFill.Size = UDim2.fromScale(1, 1)
	energyFill.BackgroundColor3 = ENERGY_COLOR
	energyFill.BorderSizePixel = 0
	energyFill.Parent = energyBackground

	local energyText = newLabel("Value", 12, energyBackground)
	energyText.Size = UDim2.fromScale(1, 1)
	energyText.ZIndex = 2

	local notice = newLabel("Notice", 18, bar)
	notice.AnchorPoint = Vector2.new(0.5, 1)
	notice.Position = UDim2.new(0.5, 0, 0, -6)
	notice.Size = UDim2.fromOffset(360, 22)
	notice.TextColor3 = NOTICE_COLOR
	notice.TextStrokeTransparency = 0.5

	local slots: { Slot } = {}
	for index, ability in LongswordConfig do
		table.insert(slots, newSlot(ability, index, bar))
	end

	gui.Parent = player:WaitForChild("PlayerGui")
	return {
		energyFill = energyFill,
		energyText = energyText,
		notice = notice,
		slots = slots,
	}
end

local function update(hud: Hud)
	local current, max = Energy.of(player)
	local energyFraction = if max > 0 then math.clamp(current / max, 0, 1) else 0
	hud.energyFill.Size = UDim2.fromScale(energyFraction, 1)
	hud.energyText.Text = `{current} / {max}`

	local now = Workspace:GetServerTimeNow()
	for _, slot in hud.slots do
		local remaining = math.max(0, CombatController.getReadyAt(slot.id) - now)
		local fraction = if slot.cooldown > 0 then math.clamp(remaining / slot.cooldown, 0, 1) else 0
		slot.shade.Size = UDim2.fromScale(1, fraction)
		slot.timer.Text = if remaining > 0 then string.format("%.1f", remaining) else ""
		slot.border.Color = if current < slot.energyCost then NO_ENERGY_COLOR else BACKGROUND_COLOR
	end

	local text, shownAt = CombatController.getLastNotice()
	hud.notice.Text = if text and os.clock() - shownAt < NOTICE_DURATION then text else ""
end

function CombatHudController:Start()
	local hud = createHud()
	RunService.RenderStepped:Connect(function()
		update(hud)
	end)
end

return CombatHudController
