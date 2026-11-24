--!strict
--[[
	EnemyBody.luau
	The placeholder body of an enemy (US-025): blocky parts welded to a HumanoidRootPart and a
	Humanoid that walks without animations (R15 rig type with a HipHeight). Elites are bigger. The
	server owns its physics (SetNetworkOwner(nil)), so no client can move it. Real models will be
	built in Studio later; EnemyService only needs a Humanoid, a HumanoidRootPart and a Torso.
]]

local EnemyBody = {}

-- Visual only: the head color, and the parts of the body (name, size and center, in studs, from
-- the ground below the body's center, before the elite scale).
local HEAD_COLOR = Color3.fromRGB(230, 190, 150)
local PARTS = {
	{ name = "LeftLeg", size = Vector3.new(1, 2, 1), center = Vector3.new(-0.5, 1, 0) },
	{ name = "RightLeg", size = Vector3.new(1, 2, 1), center = Vector3.new(0.5, 1, 0) },
	{ name = "Torso", size = Vector3.new(2, 2, 1), center = Vector3.new(0, 3, 0) },
	{ name = "Head", size = Vector3.new(1.2, 1.2, 1.2), center = Vector3.new(0, 4.6, 0) },
}
-- The root is the torso's box: its bottom stands this high above the ground (before the scale).
local ROOT_SIZE = Vector3.new(2, 2, 1)
local HIP_HEIGHT = 2

-- Builds an enemy standing at `ground` (the point on the ground below its center), facing `facing`.
-- It is not parented: the caller puts it in the Workspace and then calls `claim`.
function EnemyBody.build(
	ground: Vector3,
	facing: Vector3,
	scale: number,
	color: Color3,
	displayName: string,
	health: number,
	walkSpeed: number
): (Model, Humanoid, BasePart, BasePart)
	local model = Instance.new("Model")
	model.Name = "Enemy"
	local base = CFrame.lookAt(ground, ground + facing)

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = ROOT_SIZE * scale
	root.CFrame = base * CFrame.new(0, (HIP_HEIGHT + ROOT_SIZE.Y / 2) * scale, 0)
	root.Transparency = 1
	root.CanCollide = true
	root.Parent = model
	model.PrimaryPart = root

	local torso: BasePart = root
	for _, spec in PARTS do
		local part = Instance.new("Part")
		part.Name = spec.name
		part.Size = spec.size * scale
		part.CFrame = base * CFrame.new(spec.center * scale)
		part.Color = if spec.name == "Head" then HEAD_COLOR else color
		part.CanCollide = false
		part.Massless = true
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = model
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = part
		weld.Parent = part
		if spec.name == "Torso" then
			torso = part
		end
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.HipHeight = HIP_HEIGHT * scale
	humanoid.DisplayName = displayName
	humanoid.MaxHealth = health
	humanoid.Health = health
	humanoid.WalkSpeed = walkSpeed
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
	-- It stays on its feet: no sitting on seats, no falling over when pushed.
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid.Parent = model

	return model, humanoid, root, torso
end

-- Makes the server the owner of the body's physics. Call it once the body is in the Workspace.
function EnemyBody.claim(root: BasePart)
	if root:CanSetNetworkOwnership() then
		root:SetNetworkOwner(nil)
	end
end

-- Lets the body fall apart when the enemy dies (visual only).
function EnemyBody.fallApart(model: Model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("WeldConstraint") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
			descendant.CanCollide = true
		end
	end
end

return table.freeze(EnemyBody)
