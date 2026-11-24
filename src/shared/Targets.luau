--!strict
--[[
	Targets.luau
	What counts as a combat target (US-009): a Model with a Humanoid and the CollectionService tag
	below. Training dummies have the tag; enemies will have it too (EP-008). Used by the client's
	target lock and by the server's ability checks (US-012).
]]

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Targets = {}

-- CollectionService tag for training dummies and enemies.
Targets.TAG = "Target"

-- Whether the instance is a combat target: a Model with the tag.
function Targets.isTarget(instance: Instance): boolean
	return instance:IsA("Model") and CollectionService:HasTag(instance, Targets.TAG)
end

-- Every Model with the tag.
function Targets.all(): { Model }
	local list: { Model } = {}
	for _, instance in CollectionService:GetTagged(Targets.TAG) do
		if instance:IsA("Model") then
			table.insert(list, instance)
		end
	end
	return list
end

-- Whether the model has a Humanoid with health left.
function Targets.isAlive(model: Model): boolean
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

-- The target's position: its PrimaryPart or its HumanoidRootPart. nil if it has neither.
function Targets.position(model: Model): Vector3?
	local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end
	return nil
end

-- Whether nothing blocks the path from `origin` to `destination`, except the instances in `ignore`
-- (and everything inside them).
function Targets.hasLineOfSight(origin: Vector3, destination: Vector3, ignore: { Instance }): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	return Workspace:Raycast(origin, destination - origin, params) == nil
end

return table.freeze(Targets)
