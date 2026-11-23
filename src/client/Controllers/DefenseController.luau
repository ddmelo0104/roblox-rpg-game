--!strict
--[[
	DefenseController.luau
	Dodge and parry on PC (US-013). The dodge key dashes right away, because the client runs its own
	character's physics (prediction), in the direction the character is moving, or backwards when it
	stands still, and asks the server for the invulnerability. The parry input asks the server to
	open the parry window. The server's answer (DefenseState) says when each one is ready again and
	until when the player is vulnerable after a missed parry. DefenseEvent shows the results to
	everyone: dodged, parried (a strong signal, and the attacker is stunned), parry missed, or the
	damage taken.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes") :: ModuleScript)
local Targets = require(Shared:WaitForChild("Targets") :: ModuleScript)
local CombatConfig = require(Shared:WaitForChild("Config"):WaitForChild("Combat") :: ModuleScript)
local Items = require(Shared:WaitForChild("Items") :: ModuleScript)
local CombatEffectsController = require(script.Parent.CombatEffectsController)
local InventoryController = require(script.Parent.InventoryController)
local Notices = require(script.Parent.Parent.Notices)

type ResultStyle = { text: string, color: Color3, size: number }

-- Game text (in Portuguese) and visual settings.
local DODGE_NAME = "Esquiva"
local PARRY_NAME = "Aparar"
local RESULT_STYLES: { [string]: ResultStyle } = {
	Dodged = { text = "Esquivou", color = Color3.fromRGB(120, 220, 255), size = 22 },
	Parried = { text = "APAROU!", color = Color3.fromRGB(255, 210, 60), size = 34 },
	ParryMissed = { text = "Errou o tempo", color = Color3.fromRGB(255, 110, 90), size = 20 },
}
local HIT_COLOR = Color3.fromRGB(255, 90, 90)
local STUNNED_TEXT = "Atordoado"
local STUNNED_COLOR = Color3.fromRGB(255, 240, 150)
local GUARD_COLOR = Color3.fromRGB(255, 255, 255)
local FLASH_COLOR = Color3.fromRGB(255, 240, 200)
local FLASH_DURATION = 0.35
local MOUSE_LABELS: { [Enum.UserInputType]: string } = {
	[Enum.UserInputType.MouseButton1] = "M1",
	[Enum.UserInputType.MouseButton2] = "M2",
	[Enum.UserInputType.MouseButton3] = "M3",
}

export type Action = {
	id: string,
	name: string,
	keyLabel: string,
	cooldown: number,
}

local DefenseController = {}

-- The two defense actions, for the HUD. The dodge's cooldown comes from the boots worn now (US-024).
function DefenseController.actions(): { Action }
	return {
		{
			id = "Dodge",
			name = DODGE_NAME,
			keyLabel = CombatConfig.DODGE_KEY.Name,
			cooldown = Items.dodgeOf(InventoryController.equipped()).cooldown,
		},
		{
			id = "Parry",
			name = PARRY_NAME,
			keyLabel = MOUSE_LABELS[CombatConfig.PARRY_INPUT] or CombatConfig.PARRY_INPUT.Name,
			cooldown = CombatConfig.PARRY_MISS_LOCKOUT,
		},
	}
end

local player = Players.LocalPlayer

-- Server times, predicted here and corrected by the server (DefenseState).
local dodgeReadyAt = 0
local parryReadyAt = 0
local lockedUntil = 0

local flashFrame: Frame? = nil

local function characterParts(): (Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	return humanoid, if root and root:IsA("BasePart") then root else nil
end

-- Where the dodge goes: where the character is moving, or one step back when it stands still.
local function dodgeDirection(humanoid: Humanoid, root: BasePart): Vector3
	local moving = Vector3.new(humanoid.MoveDirection.X, 0, humanoid.MoveDirection.Z)
	if moving.Magnitude > 0.1 then
		return moving.Unit
	end
	local back = -Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	return if back.Magnitude > 0.1 then back.Unit else Vector3.new(0, 0, 1)
end

-- Pushes the character `distance` studs along `direction` in DODGE_DURATION seconds.
local function dash(root: BasePart, direction: Vector3, distance: number)
	local attachment = Instance.new("Attachment")
	attachment.Name = "DodgeAttachment"
	attachment.Parent = root

	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "DodgeVelocity"
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.MaxForce = math.huge
	velocity.VectorVelocity = direction * (distance / CombatConfig.DODGE_DURATION)
	velocity.Parent = root

	task.delay(CombatConfig.DODGE_DURATION, function()
		velocity:Destroy()
		attachment:Destroy()
	end)
end

-- A white outline on the character while the parry window is open (only this player sees it).
local function showGuard(character: Model)
	local guard = Instance.new("Highlight")
	guard.FillTransparency = 1
	guard.OutlineColor = GUARD_COLOR
	guard.Adornee = character
	guard.Parent = character
	task.delay(CombatConfig.PARRY_WINDOW, function()
		guard:Destroy()
	end)
end

-- A quick flash of the whole screen: the strong signal of a successful parry.
local function flashScreen()
	local frame = flashFrame
	if not frame or not frame.Parent then
		local gui = Instance.new("ScreenGui")
		gui.Name = "ParryFlash"
		gui.IgnoreGuiInset = true
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 10
		local created = Instance.new("Frame")
		created.Size = UDim2.fromScale(1, 1)
		created.BackgroundColor3 = FLASH_COLOR
		created.BackgroundTransparency = 1
		created.BorderSizePixel = 0
		created.Parent = gui
		gui.Parent = player:WaitForChild("PlayerGui")
		flashFrame = created
		frame = created
	end
	if frame then
		frame.BackgroundTransparency = 0.45
		TweenService:Create(frame, TweenInfo.new(FLASH_DURATION), { BackgroundTransparency = 1 }):Play()
	end
end

-- Checks shared by the dodge and the parry. Returns the reason to show, or nil if it may go on.
local function localRejectReason(readyAt: number, now: number): string?
	if now < lockedUntil then
		return "Vulnerable"
	end
	if now < readyAt then
		return "OnCooldown"
	end
	return nil
end

local function tryDodge(event: RemoteEvent)
	local humanoid, root = characterParts()
	if not humanoid or not root or humanoid.Health <= 0 then
		return
	end
	local now = Workspace:GetServerTimeNow()
	local reason = localRejectReason(dodgeReadyAt, now)
	if reason then
		Notices.showReason(DODGE_NAME, reason)
		return
	end
	-- Prediction: dash and start the cooldown now; the server confirms with DefenseState. The boots
	-- define the distance and the cooldown (US-024).
	local boots = Items.dodgeOf(InventoryController.equipped())
	dodgeReadyAt = now + boots.cooldown
	dash(root, dodgeDirection(humanoid, root), boots.distance)
	event:FireServer()
end

local function tryParry(event: RemoteEvent)
	local humanoid = characterParts()
	local character = player.Character
	if not humanoid or not character or humanoid.Health <= 0 then
		return
	end
	local now = Workspace:GetServerTimeNow()
	local reason = localRejectReason(parryReadyAt, now)
	if reason then
		Notices.showReason(PARRY_NAME, reason)
		return
	end
	parryReadyAt = now + CombatConfig.PARRY_WINDOW
	showGuard(character)
	event:FireServer()
end

-- The server's answer to this player: when dodge and parry are ready, until when the player is
-- vulnerable and, if a request was rejected, which one and why.
local function onState(
	newDodgeReadyAt: number,
	newParryReadyAt: number,
	newLockedUntil: number,
	rejected: string?,
	reason: string?
)
	dodgeReadyAt = newDodgeReadyAt
	parryReadyAt = newParryReadyAt
	lockedUntil = newLockedUntil
	if rejected and reason then
		Notices.showReason(if rejected == "Dodge" then DODGE_NAME else PARRY_NAME, reason)
	end
end

-- The server's notice to everyone: how a hit on `defender` ended.
local function onDefenseEvent(defender: Player, result: string, attacker: Instance?, damage: number)
	local character = defender.Character
	if not character then
		return
	end
	-- The strike: a short line from the attacker to the defender.
	if result ~= "ParryMissed" and attacker and attacker:IsA("Model") then
		local from = Targets.position(attacker)
		if from then
			CombatEffectsController.draw({ shape = "Target" }, CFrame.new(from), character)
		end
	end

	if result == "Hit" then
		CombatEffectsController.showText(character, tostring(math.floor(damage + 0.5)), HIT_COLOR, 24)
	else
		local style = RESULT_STYLES[result]
		if style then
			CombatEffectsController.showText(character, style.text, style.color, style.size)
		end
	end
	if result == "Parried" then
		-- A successful parry stuns the attacker.
		if attacker and attacker:IsA("Model") then
			CombatEffectsController.showText(attacker, STUNNED_TEXT, STUNNED_COLOR, 20)
		end
		if defender == player then
			flashScreen()
		end
	end
end

-- When the action ("Dodge" or "Parry") can be used again, counting the lockout. Used by the HUD.
function DefenseController.getReadyAt(actionId: string): number
	local readyAt = if actionId == "Dodge" then dodgeReadyAt else parryReadyAt
	return math.max(readyAt, lockedUntil)
end

-- Whether a missed parry left the player vulnerable right now. Used by the HUD.
function DefenseController.isVulnerable(): boolean
	return Workspace:GetServerTimeNow() < lockedUntil
end

function DefenseController:Start()
	local dodgeEvent = Remotes.event("RequestDodge")
	local parryEvent = Remotes.event("RequestParry")

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == CombatConfig.DODGE_KEY then
			tryDodge(dodgeEvent)
		elseif input.UserInputType == CombatConfig.PARRY_INPUT then
			tryParry(parryEvent)
		end
	end)

	Remotes.event("DefenseState").OnClientEvent:Connect(onState)
	Remotes.event("DefenseEvent").OnClientEvent:Connect(onDefenseEvent)
end

return DefenseController
