--!strict
--[[
	MapController.luau
	The world map (US-044, Zones and Risk tab: the map shows the color, the tier and the recommended
	GS of each zone). Config/Interface.MAP_KEY opens and closes it. The zones come from the server
	(ZoneMap), drawn from above in their colors: boxes, or circles for round regions (US-056), the
	biggest first so the city stays on top, with each zone's name written once. The player is a
	white dot. North (up on the map) is -Z. The final UI belongs to EP-011's polish.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local InterfaceConfig = require(Shared:WaitForChild("Config"):WaitForChild("Interface") :: ModuleScript)
local Remotes = require(Shared:WaitForChild("Remotes") :: ModuleScript)
local Zones = require(Shared:WaitForChild("Zones") :: ModuleScript)
local CameraController = require(script.Parent.CameraController)

-- Game text (Portuguese) and visual settings.
local TITLE = "Mapa de Stardawn"
local MAP_SIZE = 520
local PADDING = 16
local PANEL_COLOR = Color3.fromRGB(20, 20, 26)
local DOT_SIZE = 10

type Bounds = { minX: number, maxX: number, minZ: number, maxZ: number }

local MapController = {}

local player = Players.LocalPlayer
local zones: { any } = {}
local bounds: Bounds? = nil

local function newText(parent: Instance, text: string, size: number): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.TextSize = size
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.Parent = parent
	return label
end

-- The map's point for a world position.
local function toMap(x: number, z: number): UDim2
	local b = bounds :: Bounds
	local scale = (MAP_SIZE - 2 * PADDING) / math.max(b.maxX - b.minX, b.maxZ - b.minZ, 1)
	return UDim2.fromOffset(PADDING + (x - b.minX) * scale, PADDING + (z - b.minZ) * scale)
end

local function draw(area: Frame)
	for _, child in area:GetChildren() do
		if child.Name == "Zone" then
			child:Destroy()
		end
	end
	if #zones == 0 then
		bounds = nil
		return
	end
	local b = { minX = math.huge, maxX = -math.huge, minZ = math.huge, maxZ = -math.huge }
	for _, zone in zones do
		b.minX, b.maxX = math.min(b.minX, zone.minX), math.max(b.maxX, zone.maxX)
		b.minZ, b.maxZ = math.min(b.minZ, zone.minZ), math.max(b.maxZ, zone.maxZ)
	end
	bounds = b
	-- The biggest regions first, so the smaller ones (the city inside its zone) stay on top.
	local ordered = table.clone(zones)
	table.sort(ordered, function(first, second)
		return (first.maxX - first.minX) * (first.maxZ - first.minZ)
			> (second.maxX - second.minX) * (second.maxZ - second.minZ)
	end)
	for order, zone in ordered do
		local rules = Zones.rules(zone.kind)
		local topLeft = toMap(zone.minX, zone.minZ)
		local bottomRight = toMap(zone.maxX, zone.maxZ)
		local box = Instance.new("Frame")
		box.Name = "Zone"
		box.Position = topLeft
		box.Size = UDim2.fromOffset(bottomRight.X.Offset - topLeft.X.Offset, bottomRight.Y.Offset - topLeft.Y.Offset)
		box.BackgroundColor3 = rules.color
		box.BackgroundTransparency = 0.45
		box.BorderSizePixel = 0
		box.ZIndex = order
		box.Parent = area
		if zone.round then
			-- A round region (US-056): a zone made of circles looks like one.
			local round = Instance.new("UICorner")
			round.CornerRadius = UDim.new(0.5, 0)
			round.Parent = box
		else
			local stroke = Instance.new("UIStroke")
			stroke.Color = rules.color
			stroke.Thickness = 1
			stroke.Parent = box
		end
		if zone.label ~= false then
			local text = if rules.safe
				then `{zone.name}\n{rules.name}`
				else `{zone.name}\n{rules.name} T{zone.tier}\nGS {Zones.recommendedGearScore(zone.tier)}`
			local label = newText(box, text, 12)
			label.Size = UDim2.fromScale(1, 1)
			label.ZIndex = #ordered + 1
		end
	end
end

function MapController:Start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "WorldMap"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 6
	gui.Enabled = false

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(MAP_SIZE, MAP_SIZE + 30)
	panel.BackgroundColor3 = PANEL_COLOR
	panel.BackgroundTransparency = 0.1
	panel.BorderSizePixel = 0
	panel.Parent = gui
	local title = newText(panel, TITLE, 18)
	title.Size = UDim2.new(1, 0, 0, 30)

	local area = Instance.new("Frame")
	area.Position = UDim2.fromOffset(0, 30)
	area.Size = UDim2.fromOffset(MAP_SIZE, MAP_SIZE)
	area.BackgroundTransparency = 1
	area.ClipsDescendants = true
	area.Parent = panel

	local dot = Instance.new("Frame")
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Size = UDim2.fromOffset(DOT_SIZE, DOT_SIZE)
	dot.BackgroundColor3 = Color3.new(1, 1, 1)
	dot.ZIndex = 1000
	dot.Parent = area
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = dot

	gui.Parent = player:WaitForChild("PlayerGui")

	Remotes.event("ZoneMap").OnClientEvent:Connect(function(list: { any })
		zones = list
		draw(area)
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.KeyCode ~= InterfaceConfig.MAP_KEY then
			return
		end
		gui.Enabled = not gui.Enabled
		if gui.Enabled then
			CameraController.setCombatMode(false)
		end
	end)

	RunService.RenderStepped:Connect(function()
		if not gui.Enabled or not bounds then
			return
		end
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if root and root:IsA("BasePart") then
			dot.Visible = true
			dot.Position = toMap(root.Position.X, root.Position.Z)
		else
			dot.Visible = false
		end
	end)
end

return MapController
