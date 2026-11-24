--!strict
--[[
	LightingService.luau
	The light and weather of Stardawn (US-053): a fixed dawn in pink and gold, with the Atmosphere,
	the clouds, bloom and sun rays of Config/Ambience. The M1 has no day and night cycle. It is
	applied once when the game starts, unless Lighting has the attribute ManualLighting = true
	(light made by hand in Studio). The look of each zone is applied on each player's screen by the
	AmbienceController.
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AmbienceConfig = require(ReplicatedStorage.Shared.Config.Ambience)

local LightingService = {}

local function apply(instance: Instance, properties: any)
	local target: any = instance
	for property, value in properties do
		target[property] = value
	end
end

-- The first child of `className` in `parent`, created if there is none.
local function childOf(parent: Instance, className: string): Instance
	local child = parent:FindFirstChildOfClass(className)
	if child then
		return child
	end
	local created = Instance.new(className)
	created.Parent = parent
	return created
end

function LightingService:Start()
	if not AmbienceConfig.APPLY_LIGHTING or Lighting:GetAttribute(AmbienceConfig.MANUAL_ATTRIBUTE) == true then
		return
	end
	apply(Lighting, AmbienceConfig.LIGHTING)
	apply(childOf(Lighting, "Atmosphere"), AmbienceConfig.ATMOSPHERE)
	apply(childOf(Lighting, "BloomEffect"), AmbienceConfig.BLOOM)
	apply(childOf(Lighting, "SunRaysEffect"), AmbienceConfig.SUN_RAYS)
	apply(childOf(Workspace.Terrain, "Clouds"), AmbienceConfig.CLOUDS)
end

return LightingService
