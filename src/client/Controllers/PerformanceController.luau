--!strict
--[[
	PerformanceController.luau
	Performance overlay for the terrain spike (US-014). Once a second it shows the average FPS, the
	slowest frame, the client memory, the ping and the streaming settings, so the measurements on a
	modest PC and on a weak phone can be written down. Config/Debug.PERF_OVERLAY_KEY toggles it, and
	PERF_OVERLAY_VISIBLE shows it from the start.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DebugConfig = require(Shared:WaitForChild("Config"):WaitForChild("Debug") :: ModuleScript)

-- Seconds between updates of the numbers.
local UPDATE_INTERVAL = 1

local PerformanceController = {}

local player = Players.LocalPlayer

local function createLabel(): TextLabel
	local gui = Instance.new("ScreenGui")
	gui.Name = "PerformanceOverlay"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 20

	local label = Instance.new("TextLabel")
	label.Name = "Numbers"
	label.Position = UDim2.fromOffset(8, 8)
	label.Size = UDim2.fromOffset(300, 92)
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.BackgroundTransparency = 0.4
	label.BorderSizePixel = 0
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Text = "measuring..."
	label.Parent = gui

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 6)
	padding.PaddingTop = UDim.new(0, 4)
	padding.Parent = label

	gui.Enabled = DebugConfig.PERF_OVERLAY_VISIBLE
	gui.Parent = player:WaitForChild("PlayerGui")
	return label
end

local function describe(frames: number, elapsed: number, slowest: number): string
	local streaming = if Workspace.StreamingEnabled
		then `on, target {Workspace.StreamingTargetRadius} / min {Workspace.StreamingMinRadius} studs`
		else "off"
	return table.concat({
		`FPS {math.floor(frames / elapsed + 0.5)} (slowest frame {math.floor(slowest * 1000 + 0.5)} ms)`,
		`Memory {math.floor(Stats:GetTotalMemoryUsageMb() + 0.5)} MB`,
		`Ping {math.floor(player:GetNetworkPing() * 1000 + 0.5)} ms`,
		`Streaming {streaming}`,
	}, "\n")
end

function PerformanceController:Start()
	local label = createLabel()
	local gui = label.Parent :: ScreenGui

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == DebugConfig.PERF_OVERLAY_KEY then
			gui.Enabled = not gui.Enabled
		end
	end)

	local frames = 0
	local elapsed = 0
	local slowest = 0
	RunService.RenderStepped:Connect(function(dt)
		frames += 1
		elapsed += dt
		slowest = math.max(slowest, dt)
		if elapsed >= UPDATE_INTERVAL then
			if gui.Enabled then
				label.Text = describe(frames, elapsed, slowest)
			end
			frames, elapsed, slowest = 0, 0, 0
		end
	end)
end

return PerformanceController
