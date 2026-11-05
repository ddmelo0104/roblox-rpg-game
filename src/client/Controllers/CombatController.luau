--!strict
--[[
	CombatController.luau
	Abilities on PC (US-012): each key asks the server for one of the longsword's abilities. Before
	asking, the client checks what it already knows (cooldown, energy, locked target and range) to
	warn right away. Then it draws the effect and starts the cooldown without waiting for the server
	(prediction). The server decides (ADR-002, ADR-009): its answer corrects the cooldown and, if it
	rejects the request, the predicted effect disappears and the reason shows up on the HUD.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Abilities = require(Shared:WaitForChild("Abilities") :: ModuleScript)
local Energy = require(Shared:WaitForChild("Energy") :: ModuleScript)
local Remotes = require(Shared:WaitForChild("Remotes") :: ModuleScript)
local Targets = require(Shared:WaitForChild("Targets") :: ModuleScript)
local CombatConfig = require(Shared:WaitForChild("Config"):WaitForChild("Combat") :: ModuleScript)
local LongswordConfig = require(Shared:WaitForChild("Config"):WaitForChild("Longsword") :: ModuleScript)
local CombatEffectsController = require(script.Parent.CombatEffectsController)
local TargetController = require(script.Parent.TargetController)

-- What the player reads for each reason (game text, so it stays in Portuguese). The server sends the
-- reasons in Shared.Abilities; "NoLockedTarget" only comes from the client.
local REASON_TEXT: { [string]: string } = {
	NoCharacter = "sem personagem",
	OnCooldown = "em recarga",
	InvalidTarget = "alvo inválido",
	OutOfRange = "fora de alcance",
	NoLineOfSight = "sem linha de visão",
	NoEnergy = "sem energia",
	NoLockedTarget = "trave um inimigo primeiro",
}

local CombatController = {}

local player = Players.LocalPlayer

-- Server time at which each ability is ready again (predicted here, corrected by the server).
local readyAt: { [string]: number } = {}

-- The effect drawn right away for each ability, to remove if the server rejects the request.
local predictedEffect: { [string]: BasePart? } = {}

local lastNotice: string? = nil
local lastNoticeTime = 0

-- Shows "<ability name>: <reason>" on the HUD.
local function notify(abilityName: string, reason: string)
	lastNotice = `{abilityName}: {REASON_TEXT[reason] or reason}`
	lastNoticeTime = os.clock()
end

local function aliveRoot(): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
		return root
	end
	return nil
end

-- Checks what the client can check. Returns the ability's flat direction and the target that goes
-- with the request, or nil and the reason to show the player.
local function prepareRequest(ability: any, root: BasePart): (Vector3?, Model?, string?)
	if Workspace:GetServerTimeNow() < (readyAt[ability.id] or 0) then
		return nil, nil, "OnCooldown"
	end
	local currentEnergy = Energy.of(player)
	if currentEnergy < ability.energyCost then
		return nil, nil, "NoEnergy"
	end

	local origin = root.Position
	local locked = TargetController.currentTarget()
	local lockedPosition = if locked then Targets.position(locked) else nil

	if ability.shape == "Target" then
		if not locked or not lockedPosition or not Targets.isTarget(locked) or not Targets.isAlive(locked) then
			return nil, nil, "NoLockedTarget"
		end
		if not Abilities.isInRadius(origin, lockedPosition, ability.range, 0, CombatConfig.MAX_HIT_HEIGHT) then
			return nil, nil, "OutOfRange"
		end
		return Abilities.flatDirection(lockedPosition - origin), locked, nil
	end

	-- With a locked target, the ability goes toward it; without one, to where the character faces.
	local direction = if lockedPosition then lockedPosition - origin else root.CFrame.LookVector
	return Abilities.flatDirection(direction), nil, nil
end

local function useAbility(ability: any, event: RemoteEvent)
	local root = aliveRoot()
	if not root then
		return
	end
	local direction, target, reason = prepareRequest(ability, root)
	if reason then
		notify(ability.name, reason)
		return
	end
	local forward = direction or Abilities.flatDirection(root.CFrame.LookVector) or Vector3.new(0, 0, -1)

	-- Prediction: cooldown and effect right away; the server confirms or undoes them.
	readyAt[ability.id] = Workspace:GetServerTimeNow() + ability.cooldown
	local origin = CFrame.lookAt(root.Position, root.Position + forward)
	predictedEffect[ability.id] = CombatEffectsController.draw(ability, origin, target)
	event:FireServer(ability.id, forward, target)
end

-- The server's answer: when the ability is ready and, if it was rejected, why.
local function onServerResponse(id: string, ready: number, reason: string?)
	readyAt[id] = ready
	local effect = predictedEffect[id]
	predictedEffect[id] = nil
	if not reason then
		return
	end
	if effect then
		effect:Destroy()
	end
	local ability = Abilities.byId(LongswordConfig, id)
	notify(if ability then ability.name else id, reason)
end

-- Server time at which the ability is ready again (0 if it already is). Used by the HUD.
function CombatController.getReadyAt(id: string): number
	return readyAt[id] or 0
end

-- The last notice for the player and when it appeared (os.clock). Used by the HUD.
function CombatController.getLastNotice(): (string?, number)
	return lastNotice, lastNoticeTime
end

function CombatController:Start()
	local event = Remotes.event("RequestAbility")

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		for _, ability in LongswordConfig do
			if input.KeyCode == ability.key then
				useAbility(ability, event)
				return
			end
		end
	end)

	event.OnClientEvent:Connect(onServerResponse)
end

return CombatController
