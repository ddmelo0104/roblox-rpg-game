--!strict
--[[
	CombatController.luau
	Abilities on PC (US-012, US-021 to US-024): Q, E and R ask for the abilities of the weapon the
	player wears, C for the chest's ability, and the left mouse button for the basic attack. Before
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
local ArmorConfig = require(Shared:WaitForChild("Config"):WaitForChild("Armor") :: ModuleScript)
local Items = require(Shared:WaitForChild("Items") :: ModuleScript)
local Weapons = require(Shared:WaitForChild("Weapons") :: ModuleScript)
local CombatEffectsController = require(script.Parent.CombatEffectsController)
local InventoryController = require(script.Parent.InventoryController)
local TargetController = require(script.Parent.TargetController)
local Notices = require(script.Parent.Parent.Notices)

local CombatController = {}

local player = Players.LocalPlayer

-- Server time at which each ability is ready again (predicted here, corrected by the server).
local readyAt: { [string]: number } = {}

-- Server time of the next basic attack (predicted; the server keeps its own).
local basicReadyAt = 0

-- The effect drawn right away for each ability, to remove if the server rejects the request.
local predictedEffect: { [string]: BasePart? } = {}

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

	if ability.shape == "Self" then
		return Abilities.flatDirection(root.CFrame.LookVector), nil, nil
	end

	if ability.shape == "Target" then
		local isTarget = locked ~= nil and (Targets.isTarget(locked) or Players:GetPlayerFromCharacter(locked) ~= nil)
		if not locked or not lockedPosition or not isTarget or not Targets.isAlive(locked) then
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

-- Where a Ground ability lands: under the locked target if it is in range, otherwise straight ahead
-- at the ability's range (US-022).
local function groundPoint(ability: any, root: BasePart): Vector3
	local locked = TargetController.currentTarget()
	local lockedPosition = if locked then Targets.position(locked) else nil
	if lockedPosition and Abilities.isInRadius(root.Position, lockedPosition, ability.range, 0, 1e6) then
		return lockedPosition
	end
	local forward = Abilities.flatDirection(root.CFrame.LookVector) or Vector3.new(0, 0, -1)
	return root.Position + forward * ability.range
end

local function useAbility(ability: any, event: RemoteEvent)
	local root = aliveRoot()
	if not root then
		return
	end
	local direction, target, reason = prepareRequest(ability, root)
	if reason then
		Notices.showReason(ability.name, reason)
		return
	end
	local forward = direction or Abilities.flatDirection(root.CFrame.LookVector) or Vector3.new(0, 0, -1)

	-- Prediction: cooldown and effect right away; the server confirms or undoes them.
	local cooldown = ability.cooldown * InventoryController.stats().cooldownMultiplier
	readyAt[ability.id] = Workspace:GetServerTimeNow() + cooldown
	local origin = CFrame.lookAt(root.Position, root.Position + forward)
	local point = if ability.shape == "Ground" then groundPoint(ability, root) else nil
	predictedEffect[ability.id] = CombatEffectsController.draw(ability, origin, target, point)
	event:FireServer(ability.id, forward, target, point)
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
	local ability = CombatController.abilityById(id)
	Notices.showReason(if ability then ability.name else id, reason)
end

-- The abilities the player can use now: those of the weapon worn (US-021) and the chest's (US-024).
-- A chest ability has the shape "Self": no target, no direction to aim.
function CombatController.currentAbilities(): { any }
	local equipped = InventoryController.equipped()
	local list: { any } = {}
	local weapon = equipped.Weapon
	local kit = Weapons.kit(if weapon then weapon.itemId else nil)
	if kit then
		for _, ability in kit.ABILITIES do
			table.insert(list, ability)
		end
	end
	local chest = Items.chestAbilityOf(equipped)
	if chest then
		table.insert(list, {
			id = chest.id,
			name = chest.name,
			key = ArmorConfig.CHEST_ABILITY_KEY,
			shape = "Self",
			range = 0,
			energyCost = chest.energyCost,
			cooldown = chest.cooldown,
		})
	end
	return list
end

-- Any ability by id: of a weapon kit or of a chest.
function CombatController.abilityById(id: string): any
	local ability = Weapons.abilityById(id)
	if ability then
		return ability
	end
	for _, chest in ArmorConfig.CHEST_ABILITIES do
		if chest.id == id then
			return chest
		end
	end
	return nil
end

-- Server time at which the ability is ready again (0 if it already is). Used by the HUD.
function CombatController.getReadyAt(id: string): number
	return readyAt[id] or 0
end

function CombatController:Start()
	local event = Remotes.event("RequestAbility")

	local basicEvent = Remotes.event("RequestBasicAttack")

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			-- Basic attack (US-023): the server picks the locked target or assists the aim.
			if aliveRoot() and Workspace:GetServerTimeNow() >= basicReadyAt then
				local weapon = InventoryController.equipped().Weapon
				local kit = Weapons.kit(if weapon then weapon.itemId else nil)
				if kit then
					basicReadyAt = Workspace:GetServerTimeNow() + kit.BASIC_ATTACK.interval
					basicEvent:FireServer(TargetController.currentTarget())
				end
			end
			return
		end
		for _, ability in CombatController.currentAbilities() do
			if input.KeyCode == ability.key then
				useAbility(ability, event)
				return
			end
		end
	end)

	event.OnClientEvent:Connect(onServerResponse)
end

return CombatController
