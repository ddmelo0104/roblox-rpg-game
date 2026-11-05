--!strict
--[[
	CombatEffectsController.luau
	Ability effects (US-012), visual only: the drawing of the area (or of the strike up to the
	target) and the damage number above whoever was hit. Whoever uses the ability draws it right
	away, through the CombatController; the other players draw it when the server says so
	(AbilityUsed). The damage number is always the one the server applied.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Abilities = require(Shared:WaitForChild("Abilities") :: ModuleScript)
local Remotes = require(Shared:WaitForChild("Remotes") :: ModuleScript)
local Targets = require(Shared:WaitForChild("Targets") :: ModuleScript)
local LongswordConfig = require(Shared:WaitForChild("Config"):WaitForChild("Longsword") :: ModuleScript)

-- Visual only: how long each effect stays on screen and the color of each ability shape.
local AREA_DURATION = 0.35
local NUMBER_DURATION = 0.8
local NUMBER_RISE = 2
local SHAPE_COLORS: { [string]: Color3 } = {
	Front = Color3.fromRGB(255, 220, 120),
	Target = Color3.fromRGB(255, 120, 90),
	Around = Color3.fromRGB(140, 200, 255),
}

local CombatEffectsController = {}

local player = Players.LocalPlayer
local folder: Folder? = nil

-- Local folder (this client only) for the effects.
local function effectsFolder(): Folder
	local current = folder
	if current and current.Parent then
		return current
	end
	local created = Instance.new("Folder")
	created.Name = "CombatEffects"
	created.Parent = Workspace
	folder = created
	return created
end

-- A decorative part: it does not collide, is not touched and blocks no raycasts (not even the
-- target lock's).
local function newPart(color: Color3): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Transparency = 0.5
	return part
end

-- Fades out and destroys itself.
local function fadeOut(part: BasePart)
	TweenService:Create(part, TweenInfo.new(AREA_DURATION), { Transparency = 1 }):Play()
	task.delay(AREA_DURATION, function()
		part:Destroy()
	end)
end

-- Draws the ability from `origin` (position and direction of whoever used it), at waist height.
-- Returns the drawn part, so whoever predicted it can remove it if the server rejects the request.
function CombatEffectsController.draw(ability: any, origin: CFrame, target: Model?): BasePart?
	local part = newPart(SHAPE_COLORS[ability.shape] or Color3.new(1, 1, 1))
	if ability.shape == "Front" then
		part.Size = Vector3.new(ability.width, 0.2, ability.range)
		part.CFrame = origin * CFrame.new(0, 0, -ability.range / 2)
	elseif ability.shape == "Around" then
		-- The cylinder's axis is X; turned 90° around Z, it stands up and becomes a flat disc.
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(0.2, ability.range * 2, ability.range * 2)
		part.CFrame = CFrame.new(origin.Position) * CFrame.Angles(0, 0, math.rad(90))
	else
		local position = if target then Targets.position(target) else nil
		local distance = if position then (position - origin.Position).Magnitude else 0
		if not position or distance < 0.5 then
			part:Destroy()
			return nil
		end
		part.Size = Vector3.new(0.4, 0.4, distance)
		part.CFrame = CFrame.lookAt(origin.Position, position) * CFrame.new(0, 0, -distance / 2)
	end
	part.Parent = effectsFolder()
	fadeOut(part)
	return part
end

-- Shows the damage rising and fading above the target.
function CombatEffectsController.showDamage(target: Model, damage: number)
	local root = target.PrimaryPart or target:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(80, 30)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = root

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextSize = 24
	label.TextColor3 = Color3.fromRGB(255, 230, 120)
	label.TextStrokeTransparency = 0.3
	label.Text = tostring(math.floor(damage + 0.5))
	label.Parent = billboard
	billboard.Parent = effectsFolder()

	local info = TweenInfo.new(NUMBER_DURATION)
	TweenService:Create(billboard, info, { StudsOffset = billboard.StudsOffset + Vector3.new(0, NUMBER_RISE, 0) })
		:Play()
	TweenService:Create(label, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(NUMBER_DURATION, function()
		billboard:Destroy()
	end)
end

-- The server's notice: someone used an ability from `origin` and hit `hits`.
local function onAbilityUsed(user: Player, id: string, origin: CFrame, hits: { Model }, damage: number)
	local ability = Abilities.byId(LongswordConfig, id)
	if not ability then
		return
	end
	-- Whoever used it already drew it (prediction); the others draw it now.
	if user ~= player then
		CombatEffectsController.draw(ability, origin, hits[1])
	end
	for _, target in hits do
		CombatEffectsController.showDamage(target, damage)
	end
end

function CombatEffectsController:Start()
	Remotes.event("AbilityUsed").OnClientEvent:Connect(onAbilityUsed)
end

return CombatEffectsController
