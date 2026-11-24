--!strict
--[[
	DecorController.luau
	The decor that should look alive (US-052). Models and parts tagged Spin turn around their vertical
	axis (attribute SpinSpeed, degrees per second) and float up and down (BobHeight), like the Star of
	the city's monument. It runs on this player's screen only, and only near the camera. Parts that
	stream in later take their place in the turn, since they arrive in the pose the server gave them.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local World = require(Shared:WaitForChild("World") :: ModuleScript)

-- Studs from the camera beyond which the decor stays still, and how fast it floats (radians per
-- second).
local MAX_DISTANCE = 400
local BOB_RATE = 1.2

type Spinner = {
	base: CFrame,
	offsets: { [BasePart]: CFrame },
	speed: number,
	bob: number,
	connections: { RBXScriptConnection },
}

local DecorController = {}

local spinners: { [Instance]: Spinner } = {}

local function attribute(instance: Instance, name: string): number
	local value = instance:GetAttribute(name)
	return if typeof(value) == "number" then value else 0
end

local function add(instance: Instance)
	if spinners[instance] then
		return
	end
	local base: CFrame
	if instance:IsA("Model") then
		base = instance:GetPivot()
	elseif instance:IsA("BasePart") then
		base = instance.CFrame
	else
		return
	end
	local spinner: Spinner = {
		base = base,
		offsets = {},
		speed = attribute(instance, World.SPIN_SPEED),
		bob = attribute(instance, World.BOB_HEIGHT),
		connections = {},
	}
	local function track(part: Instance)
		if part:IsA("BasePart") then
			spinner.offsets[part] = base:ToObjectSpace(part.CFrame)
		end
	end
	track(instance)
	for _, descendant in instance:GetDescendants() do
		track(descendant)
	end
	table.insert(spinner.connections, instance.DescendantAdded:Connect(track))
	table.insert(
		spinner.connections,
		instance.DescendantRemoving:Connect(function(descendant)
			if descendant:IsA("BasePart") then
				spinner.offsets[descendant] = nil
			end
		end)
	)
	spinners[instance] = spinner
end

local function remove(instance: Instance)
	local spinner = spinners[instance]
	if spinner then
		for _, connection in spinner.connections do
			connection:Disconnect()
		end
		spinners[instance] = nil
	end
end

function DecorController:Start()
	CollectionService:GetInstanceAddedSignal(World.SPIN_TAG):Connect(add)
	CollectionService:GetInstanceRemovedSignal(World.SPIN_TAG):Connect(remove)
	for _, instance in CollectionService:GetTagged(World.SPIN_TAG) do
		add(instance)
	end
	RunService.RenderStepped:Connect(function()
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local now = os.clock()
		local eye = camera.CFrame.Position
		for _, spinner in spinners do
			if (spinner.base.Position - eye).Magnitude <= MAX_DISTANCE then
				local pivot = spinner.base
					* CFrame.new(0, math.sin(now * BOB_RATE) * spinner.bob, 0)
					* CFrame.Angles(0, math.rad(now * spinner.speed % 360), 0)
				for part, offset in spinner.offsets do
					part.CFrame = pivot * offset
				end
			end
		end
	end)
end

return DecorController
