--!strict
--[[
	MovementValidationService.luau
	Server check of how far each character moves (US-011, ADR-010 proposed, Movement tab). The
	client runs its own character's physics, so without this check a speed hack or a teleport would
	be accepted.

	Every Config/Movement.VALIDATION_INTERVAL, the horizontal distance moved since the last valid
	position is compared with a movement budget. The budget grows with the speed the server allows
	(MovementService) plus SPEED_MARGIN, and unused budget is kept for up to MAX_LAG_BURST seconds of
	movement, so a lagging player who delivers several moves at once is not punished. A character
	that goes past its budget plus DISTANCE_TOLERANCE is pulled back to the last valid position.

	Only horizontal distance is checked, so falling is free; flying and walking through walls come
	later. Moves made or approved by the server do not count: respawns reset the check, and
	`teleport` and `allowExtraDistance` cover teleports and dashes (the dodge).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovementConfig = require(ReplicatedStorage.Shared.Config.Movement)
local MovementService = require(script.Parent.MovementService)

type State = {
	character: Model,
	-- Last position that passed the check.
	anchor: Vector3,
	-- Studs the player may still move without being pulled back.
	budget: number,
	-- Studs approved by the server on top of the budget (a dash), used up in the next check.
	extra: number,
}

local MovementValidationService = {}

local states: { [Player]: State } = {}

local function rootOf(character: Model): BasePart?
	local root = character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function flatDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function resetState(player: Player, character: Model, root: BasePart)
	states[player] = { character = character, anchor = root.Position, budget = 0, extra = 0 }
end

local function check(player: Player, dt: number)
	local character = player.Character
	local root = if character then rootOf(character) else nil
	if not character or not root or root.Anchored then
		return
	end
	local state = states[player]
	if not state or state.character ~= character then
		-- A new character (join or respawn): the server placed it, so its first position is valid.
		resetState(player, character, root)
		return
	end

	local speed = MovementService.allowedSpeed(player)
	local maxBudget = speed * MovementConfig.MAX_LAG_BURST
	state.budget = math.min(state.budget + speed * dt * (1 + MovementConfig.SPEED_MARGIN), maxBudget)

	local moved = flatDistance(root.Position, state.anchor)
	local allowed = state.budget + state.extra + MovementConfig.DISTANCE_TOLERANCE
	if moved > allowed then
		warn(
			`[MovementValidation] pulled {player.Name} back: moved {math.floor(moved)} studs,`
				.. ` allowed {math.floor(allowed)}`
		)
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = CFrame.new(state.anchor) * root.CFrame.Rotation
		state.budget = 0
		state.extra = 0
		return
	end

	state.budget = math.clamp(state.budget + state.extra - moved, 0, maxBudget)
	state.extra = 0
	state.anchor = root.Position
end

-- Moves the player's character from the server (portals, teleports) without it counting as a cheat.
function MovementValidationService.teleport(player: Player, cframe: CFrame)
	local character = player.Character
	local root = if character then rootOf(character) else nil
	if not character or not root then
		return
	end
	root.CFrame = cframe
	resetState(player, character, root)
end

-- Lets the player move `studs` more than their speed allows in the next check (a server-approved
-- dash, such as the dodge).
function MovementValidationService.allowExtraDistance(player: Player, studs: number)
	local state = states[player]
	if state then
		state.extra += studs
	end
end

function MovementValidationService:Start()
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)

	task.spawn(function()
		local lastCheck = os.clock()
		while true do
			task.wait(MovementConfig.VALIDATION_INTERVAL)
			local now = os.clock()
			local dt = now - lastCheck
			lastCheck = now
			for _, player in Players:GetPlayers() do
				-- One player's error must not stop the checks of everyone else.
				local ok, err = pcall(check, player, dt)
				if not ok then
					warn(`[MovementValidation] check failed for {player.Name}: {err}`)
				end
			end
		end
	end)
end

return MovementValidationService
