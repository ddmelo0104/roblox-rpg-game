--!strict
--[[
	AmbienceController.luau
	The look of each zone on this player's screen (US-053). Entering a zone tweens a tint of the image
	(ColorCorrection) and the haze of the Atmosphere to the zone's look in Config/Ambience. The risk is
	felt before it is read: the Blue is clear, the city warm, the Yellow golden, the Red dull and
	reddish, and dungeons are darker. Only this player's screen changes. With ManualLighting on
	Lighting (light made by hand in Studio), only the tint changes.
]]

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Zones = require(Shared:WaitForChild("Zones") :: ModuleScript)
local AmbienceConfig = require(Shared:WaitForChild("Config"):WaitForChild("Ambience") :: ModuleScript)

local AmbienceController = {}

local player = Players.LocalPlayer
local tint: ColorCorrectionEffect? = nil

local function currentLook(): any
	if player:GetAttribute(Zones.DUNGEON_ATTRIBUTE) == true then
		return AmbienceConfig.DUNGEON
	end
	local kind = player:GetAttribute(Zones.KIND_ATTRIBUTE)
	local look = if typeof(kind) == "string" then AmbienceConfig.ZONES[kind] else nil
	return look or AmbienceConfig.ZONES.Blue
end

local function apply()
	local look = currentLook()
	local info = TweenInfo.new(AmbienceConfig.TRANSITION_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	if tint then
		TweenService:Create(tint, info, {
			TintColor = look.tint,
			Saturation = look.saturation,
			Contrast = look.contrast,
			Brightness = look.brightness,
		}):Play()
	end
	if Lighting:GetAttribute(AmbienceConfig.MANUAL_ATTRIBUTE) ~= true then
		local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
		if atmosphere then
			TweenService:Create(atmosphere, info, { Density = look.density, Haze = look.haze, Color = look.color })
				:Play()
		end
	end
end

function AmbienceController:Start()
	local effect = Instance.new("ColorCorrectionEffect")
	effect.Name = "ZoneTint"
	effect.Parent = Lighting
	tint = effect
	player:GetAttributeChangedSignal(Zones.KIND_ATTRIBUTE):Connect(apply)
	player:GetAttributeChangedSignal(Zones.DUNGEON_ATTRIBUTE):Connect(apply)
	Lighting.ChildAdded:Connect(function(child)
		if child:IsA("Atmosphere") then
			apply()
		end
	end)
	apply()
end

return AmbienceController
