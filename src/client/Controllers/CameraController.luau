--!strict
--[[
	CameraController.luau
	PC camera (US-009, Camera and Aim tab): third person with limited zoom, plus combat mode, the
	game's own shift-lock. In combat mode the mouse is locked to the center, the camera moves to the
	shoulder and the character turns to where the camera points. With a locked target (set by the
	TargetController), the camera and the character follow the target.
	Everything here is visual: the server trusts neither the camera nor the lock (ADR-002).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CameraConfig = require(Shared:WaitForChild("Config"):WaitForChild("Camera") :: ModuleScript)
local Targets = require(Shared:WaitForChild("Targets") :: ModuleScript)

local CameraController = {}

local player = Players.LocalPlayer
local combatMode = false
local lockedTarget: Model? = nil

local function characterParts(): (Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return humanoid, root
	end
	return humanoid, nil
end

-- Turns the character toward a direction, on the ground plane only (rotation around Y).
local function faceDirection(root: BasePart, direction: Vector3)
	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude > 0.01 then
		root.CFrame = CFrame.lookAt(root.Position, root.Position + flat.Unit)
	end
end

-- With a target: the camera stays behind the shoulder, looking at the target, at the current zoom
-- distance.
local function aimAtTarget(camera: Camera, root: BasePart, targetPosition: Vector3)
	local focus = root.Position + Vector3.new(0, CameraConfig.FOCUS_HEIGHT, 0)
	if (targetPosition - focus).Magnitude < 1 then
		return
	end
	local distance = (camera.CFrame.Position - camera.Focus.Position).Magnitude
	local shoulder = CameraConfig.SHOULDER_OFFSET
	local look = CFrame.lookAt(focus, targetPosition)
	local cameraPosition = (look * CFrame.new(shoulder.X, shoulder.Y, distance)).Position
	camera.CFrame = CFrame.lookAt(cameraPosition, targetPosition)
end

-- Runs every frame, right after Roblox's default camera.
local function onRenderStep()
	if not combatMode then
		return
	end
	local humanoid, root = characterParts()
	local camera = Workspace.CurrentCamera
	if not humanoid or not root or not camera or humanoid.Health <= 0 then
		return
	end

	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	humanoid.AutoRotate = false
	humanoid.CameraOffset = CameraConfig.SHOULDER_OFFSET

	local targetPosition = if lockedTarget then Targets.position(lockedTarget) else nil
	if targetPosition then
		aimAtTarget(camera, root, targetPosition)
		faceDirection(root, targetPosition - root.Position)
	else
		faceDirection(root, camera.CFrame.LookVector)
	end
end

function CameraController.isInCombatMode(): boolean
	return combatMode
end

function CameraController.setCombatMode(enabled: boolean)
	if combatMode == enabled then
		return
	end
	combatMode = enabled
	if not enabled then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		local humanoid = characterParts()
		if humanoid then
			humanoid.AutoRotate = true
			humanoid.CameraOffset = Vector3.zero
		end
	end
end

-- Called by the TargetController: the Model when locking, nil when releasing.
function CameraController.setTarget(target: Model?)
	lockedTarget = target
end

function CameraController:Start()
	player.CameraMinZoomDistance = CameraConfig.ZOOM_MIN
	player.CameraMaxZoomDistance = CameraConfig.ZOOM_MAX

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == CameraConfig.COMBAT_MODE_KEY then
			CameraController.setCombatMode(not combatMode)
		end
	end)

	RunService:BindToRenderStep("CombatMode", Enum.RenderPriority.Camera.Value + 1, onRenderStep)
end

return CameraController
