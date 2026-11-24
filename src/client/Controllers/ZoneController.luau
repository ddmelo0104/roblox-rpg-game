--!strict
--[[
	ZoneController.luau
	What the player sees of the zones (US-035, US-037), from the attributes the server publishes
	(Shared.Zones):
	- at the top of the screen, the zone's name, kind and tier in its color, and the recommended GS;
	- when the zone changes, a banner with what the zone means ("PvP livre e saque total");
	- the first time in a session that the player enters a zone of risk (full loot), a full-screen
	  warning; and a red border on the screen while they are in one;
	- the seconds left of the protection after entering a PvP zone.
	Risk is always a choice, and always warned (Zones and Risk tab).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Zones = require(Shared:WaitForChild("Zones") :: ModuleScript)

-- Game text (Portuguese) and visual settings.
local RISK_WARNING_TITLE = "Zona de risco"
local RISK_WARNING_TEXT = "Aqui você pode perder tudo o que carrega.\nOutros jogadores podem te atacar."
local RISK_WARNING_TIME = 5
local BANNER_TIME = 4
local BORDER_THICKNESS = 6
local BORDER_COLOR = Color3.fromRGB(230, 60, 60)
local PROTECTION_COLOR = Color3.fromRGB(150, 230, 150)

type Hud = {
	gui: ScreenGui,
	label: TextLabel,
	protection: TextLabel,
	banner: TextLabel,
	warning: Frame,
	border: Frame,
}

local ZoneController = {}

local player = Players.LocalPlayer
-- Zone kinds whose risk warning this session already showed.
local warned: { [string]: boolean } = {}

local function newLabel(parent: Instance, size: UDim2, position: UDim2, textSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Size = size
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

local function createHud(): Hud
	local gui = Instance.new("ScreenGui")
	gui.Name = "ZoneHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 3

	local border = Instance.new("Frame")
	border.Size = UDim2.fromScale(1, 1)
	border.BackgroundTransparency = 1
	border.Visible = false
	border.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = BORDER_THICKNESS
	stroke.Color = BORDER_COLOR
	stroke.Transparency = 0.2
	stroke.Parent = border

	local label = newLabel(gui, UDim2.fromOffset(600, 24), UDim2.new(0.5, 0, 0, 44), 18)
	local protection = newLabel(gui, UDim2.fromOffset(600, 20), UDim2.new(0.5, 0, 0, 68), 15)
	protection.TextColor3 = PROTECTION_COLOR
	local banner = newLabel(gui, UDim2.fromOffset(700, 30), UDim2.new(0.5, 0, 0.22, 0), 24)
	banner.TextTransparency = 1
	banner.TextStrokeTransparency = 1

	local warning = Instance.new("Frame")
	warning.Size = UDim2.fromScale(1, 1)
	warning.BackgroundColor3 = Color3.new(0, 0, 0)
	warning.BackgroundTransparency = 0.35
	warning.Visible = false
	warning.Parent = gui
	local title = newLabel(warning, UDim2.fromOffset(800, 48), UDim2.fromScale(0.5, 0.38), 40)
	title.TextColor3 = BORDER_COLOR
	title.Text = RISK_WARNING_TITLE
	local text = newLabel(warning, UDim2.fromOffset(800, 80), UDim2.fromScale(0.5, 0.46), 24)
	text.Text = RISK_WARNING_TEXT

	gui.Parent = player:WaitForChild("PlayerGui")
	return { gui = gui, label = label, protection = protection, banner = banner, warning = warning, border = border }
end

-- The zone the server says the player is in, or nil before the first check.
local function currentZone(): (string?, number, string)
	local kind = player:GetAttribute(Zones.KIND_ATTRIBUTE)
	local tier = player:GetAttribute(Zones.TIER_ATTRIBUTE)
	local name = player:GetAttribute(Zones.NAME_ATTRIBUTE)
	if typeof(kind) ~= "string" then
		return nil, 0, ""
	end
	return kind, if typeof(tier) == "number" then tier else 1, if typeof(name) == "string" then name else ""
end

local function showBanner(hud: Hud, text: string, color: Color3)
	local banner = hud.banner
	banner.Text = text
	banner.TextColor3 = color
	banner.TextTransparency = 0
	banner.TextStrokeTransparency = 0.4
	task.delay(BANNER_TIME, function()
		if banner.Text == text then
			TweenService:Create(banner, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

local function showWarning(hud: Hud)
	hud.warning.Visible = true
	task.delay(RISK_WARNING_TIME, function()
		hud.warning.Visible = false
	end)
end

local function onZoneChanged(hud: Hud)
	local kind, tier, name = currentZone()
	if not kind then
		return
	end
	local rules = Zones.rules(kind)
	local gearScore = Zones.recommendedGearScore(tier)
	hud.label.Text = if rules.safe
		then `{name} · {rules.name}`
		else `{name} · {rules.name} T{tier} · GS recomendado {gearScore}`
	hud.label.TextColor3 = rules.color
	hud.border.Visible = rules.risk == true
	showBanner(hud, `{rules.name}: {rules.summary}`, rules.color)
	if rules.risk and not warned[kind] then
		warned[kind] = true
		showWarning(hud)
	end
end

function ZoneController:Start()
	local hud = createHud()
	player:GetAttributeChangedSignal(Zones.NAME_ATTRIBUTE):Connect(function()
		onZoneChanged(hud)
	end)
	player:GetAttributeChangedSignal(Zones.KIND_ATTRIBUTE):Connect(function()
		onZoneChanged(hud)
	end)
	onZoneChanged(hud)

	-- The protection countdown, a few times a second.
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.2 then
			return
		end
		elapsed = 0
		local untilTime = player:GetAttribute(Zones.PROTECTED_UNTIL)
		local left = if typeof(untilTime) == "number" then untilTime - Workspace:GetServerTimeNow() else 0
		hud.protection.Text = if left > 0 then `Protegido de outros jogadores: {math.ceil(left)} s` else ""
	end)
end

return ZoneController
