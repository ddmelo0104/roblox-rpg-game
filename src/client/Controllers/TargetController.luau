--!strict
--[[
	TargetController.luau
	Target lock (US-009, Camera and Aim tab). Locking picks the valid target closest to the camera's
	center and turns combat mode on; the switch key moves the lock to another target; locking again
	releases it. The lock also releases by itself when the target dies, leaves the range, stays out
	of sight for a while, or when combat mode is turned off.
	Client only: the server always checks target, range and line of sight for abilities (ADR-002).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CameraConfig = require(Shared:WaitForChild("Config"):WaitForChild("Camera") :: ModuleScript)
local Targets = require(Shared:WaitForChild("Targets") :: ModuleScript)
local CameraController = require(script.Parent.CameraController)

-- Outline color of the locked target (visual only).
local OUTLINE_COLOR = Color3.fromRGB(255, 196, 0)

local TargetController = {}

local player = Players.LocalPlayer
local target: Model? = nil
local outline: Highlight? = nil
local timeWithoutSight = 0

local function playerRoot(): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function focusOf(root: BasePart): Vector3
	return root.Position + Vector3.new(0, CameraConfig.FOCUS_HEIGHT, 0)
end

-- The models that can be locked: the ones with the target tag and, if the Config allows it, the
-- other players.
local function candidates(): { Model }
	local list = Targets.all()
	if CameraConfig.LOCK_ON_PLAYERS then
		for _, other in Players:GetPlayers() do
			local character = other.Character
			if other ~= player and character then
				table.insert(list, character)
			end
		end
	end
	return list
end

local function hasLineOfSight(origin: Vector3, model: Model, destination: Vector3): boolean
	local ignore: { Instance } = { model }
	local character = player.Character
	if character then
		table.insert(ignore, character)
	end
	return Targets.hasLineOfSight(origin, destination, ignore)
end

-- The living, visible target, in range and within the camera's angle, closest to the screen's center.
local function bestTarget(except: Model?): Model?
	local root = playerRoot()
	local camera = Workspace.CurrentCamera
	if not root or not camera then
		return nil
	end
	local origin = focusOf(root)
	local look = camera.CFrame.LookVector
	local minCos = math.cos(math.rad(CameraConfig.LOCK_ANGLE))
	local best: Model? = nil
	local bestCos = -math.huge

	for _, model in candidates() do
		local position = Targets.position(model)
		if model == except or not position or not Targets.isAlive(model) then
			continue
		end
		local toTarget = position - origin
		local distance = toTarget.Magnitude
		if distance < 0.5 or distance > CameraConfig.LOCK_RANGE then
			continue
		end
		local cosAngle = look:Dot(toTarget.Unit)
		if cosAngle > bestCos and cosAngle >= minCos and hasLineOfSight(origin, model, position) then
			best = model
			bestCos = cosAngle
		end
	end
	return best
end

local function release()
	target = nil
	timeWithoutSight = 0
	if outline then
		outline:Destroy()
		outline = nil
	end
	CameraController.setTarget(nil)
end

local function lock(model: Model)
	release()
	target = model

	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 0.85
	highlight.OutlineColor = OUTLINE_COLOR
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Adornee = model
	highlight.Parent = model
	outline = highlight

	CameraController.setCombatMode(true)
	CameraController.setTarget(model)
end

-- Every frame, checks whether the lock still holds.
local function checkLock(dt: number)
	local current = target
	if not current then
		return
	end
	local root = playerRoot()
	local position = Targets.position(current)
	if not CameraController.isInCombatMode() or not root or not position or not Targets.isAlive(current) then
		release()
		return
	end
	local origin = focusOf(root)
	if (position - origin).Magnitude > CameraConfig.LOCK_RANGE then
		release()
		return
	end
	if hasLineOfSight(origin, current, position) then
		timeWithoutSight = 0
	else
		timeWithoutSight += dt
		if timeWithoutSight >= CameraConfig.LOST_SIGHT_RELEASE_TIME then
			release()
		end
	end
end

local function toggleLock()
	if target then
		release()
		return
	end
	local chosen = bestTarget(nil)
	if chosen then
		lock(chosen)
	end
end

local function switchTarget()
	local current = target
	if not current then
		return
	end
	local nextTarget = bestTarget(current)
	if nextTarget then
		lock(nextTarget)
	end
end

-- The currently locked target, or nil. Used by the abilities (US-012).
function TargetController.currentTarget(): Model?
	return target
end

function TargetController:Start()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == CameraConfig.LOCK_KEY or input.UserInputType == Enum.UserInputType.MouseButton3 then
			toggleLock()
		elseif input.KeyCode == CameraConfig.SWITCH_TARGET_KEY then
			switchTarget()
		end
	end)

	RunService.Heartbeat:Connect(checkLock)
	player.CharacterAdded:Connect(release)
end

return TargetController
