--!strict
--[[
	DefenseService.luau
	Dodge and parry (US-013, Combat and Abilities tab). The client asks to dodge or to parry; the
	server checks the cooldown and the lockout, then opens the invulnerability or the parry window.
	Every hit on a player goes through `receiveHit`: it waits DEFENSE_GRACE, so the defender wins
	close calls, resolves the hit as dodged, parried or hit, applies the damage and tells every
	client. A parry that catches no hit leaves the player vulnerable for a moment: no dodge and no
	parry. A successful parry stuns the attacker (Davi, 2026-11-23).
	Numbers in Config/Combat.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CombatConfig = require(ReplicatedStorage.Shared.Config.Combat)
local Defense = require(ReplicatedStorage.Shared.Defense)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Network = require(script.Parent.Parent.Network)
local CombatStateService = require(script.Parent.CombatStateService)
local MovementValidationService = require(script.Parent.MovementValidationService)
local StatsService = require(script.Parent.StatsService)
local StatusService = require(script.Parent.StatusService)

type State = {
	dodgeReadyAt: number,
	parryReadyAt: number,
	-- After a missed parry, no dodge or parry until this server time.
	lockedUntil: number,
	invulnerableFrom: number,
	invulnerableUntil: number,
	parryFrom: number,
	parryUntil: number,
	-- Bumped at every parry, so a late miss check never touches a newer window.
	parryId: number,
	parryCaughtHit: boolean,
}

local DefenseService = {}

local states: { [Player]: State } = {}

local stateEvent = Remotes.event("DefenseState")
local resultEvent = Remotes.event("DefenseEvent")

local function newState(): State
	return {
		dodgeReadyAt = 0,
		parryReadyAt = 0,
		lockedUntil = 0,
		invulnerableFrom = 0,
		invulnerableUntil = 0,
		parryFrom = 0,
		parryUntil = 0,
		parryId = 0,
		parryCaughtHit = false,
	}
end

local function stateOf(player: Player): State
	local existing = states[player]
	if existing then
		return existing
	end
	local created = newState()
	states[player] = created
	return created
end

-- Tells the player's client when the dodge and the parry are ready again, until when the player is
-- vulnerable and, if a request was rejected, which one and why.
local function sendState(player: Player, rejected: Defense.Action?, reason: Defense.RejectReason?)
	local state = stateOf(player)
	stateEvent:FireClient(player, state.dodgeReadyAt, state.parryReadyAt, state.lockedUntil, rejected, reason)
end

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	return if character then character:FindFirstChildOfClass("Humanoid") else nil
end

-- The checks shared by the dodge and the parry. Returns why the request is rejected, or nil.
local function rejectReason(player: Player, readyAt: number, now: number): Defense.RejectReason?
	local humanoid = humanoidOf(player)
	if not humanoid or humanoid.Health <= 0 then
		return "NoCharacter"
	end
	if now < stateOf(player).lockedUntil then
		return "Vulnerable"
	end
	if now < readyAt then
		return "OnCooldown"
	end
	return nil
end

local function dodge(player: Player)
	local state = stateOf(player)
	local now = Workspace:GetServerTimeNow()
	local reason = rejectReason(player, state.dodgeReadyAt, now)
	if reason then
		sendState(player, "Dodge", reason)
		return
	end
	state.invulnerableFrom = now
	state.invulnerableUntil = now + CombatConfig.DODGE_INVULNERABLE_TIME
	state.dodgeReadyAt = now + CombatConfig.DODGE_COOLDOWN
	-- The client dashes on its own, because it runs its character's physics; the movement validation
	-- lets that dash through.
	MovementValidationService.allowExtraDistance(player, CombatConfig.DODGE_DISTANCE)
	sendState(player, nil, nil)
end

local function parry(player: Player)
	local state = stateOf(player)
	local now = Workspace:GetServerTimeNow()
	local reason = rejectReason(player, state.parryReadyAt, now)
	if reason then
		sendState(player, "Parry", reason)
		return
	end
	state.parryFrom = now
	state.parryUntil = now + CombatConfig.PARRY_WINDOW
	state.parryReadyAt = state.parryUntil
	state.parryId += 1
	state.parryCaughtHit = false
	sendState(player, nil, nil)

	-- A parry that caught no hit leaves the player vulnerable for a moment (against auto-parry). The
	-- check waits for every hit inside the window to be resolved first.
	local id = state.parryId
	task.delay(CombatConfig.PARRY_WINDOW + 2 * CombatConfig.DEFENSE_GRACE, function()
		if states[player] ~= state or state.parryId ~= id or state.parryCaughtHit then
			return
		end
		state.lockedUntil = Workspace:GetServerTimeNow() + CombatConfig.PARRY_MISS_LOCKOUT
		sendState(player, nil, nil)
		resultEvent:FireAllClients(player, "ParryMissed", nil, 0)
	end)
end

-- A hit of `damage` lands on the player now. Waits DEFENSE_GRACE, so a defense that started a bit
-- after the hit still counts; then resolves the hit, applies the damage if it got through and tells
-- every client. Yields; returns the result.
function DefenseService.receiveHit(
	player: Player,
	damage: number,
	kind: Defense.HitKind,
	attacker: Instance?
): Defense.Result
	local hitTime = Workspace:GetServerTimeNow()
	task.wait(CombatConfig.DEFENSE_GRACE)
	if not player.Parent then
		return "Hit" -- the player left the game meanwhile
	end

	local state = stateOf(player)
	local grace = CombatConfig.DEFENSE_GRACE
	local result: Defense.Result = if Defense.covers(state.invulnerableFrom, state.invulnerableUntil, hitTime, grace)
		then "Dodged"
		elseif kind == "Melee" and Defense.covers(state.parryFrom, state.parryUntil, hitTime, grace) then "Parried"
		else "Hit"

	if result == "Parried" then
		state.parryCaughtHit = true
		if attacker and attacker:IsA("Model") then
			StatusService.stun(attacker, CombatConfig.PARRY_STUN_TIME)
		end
	elseif result == "Hit" then
		-- The equipment's resistance removes part of the damage (US-018).
		damage *= 1 - StatsService.of(player).resistance
		local humanoid = humanoidOf(player)
		if humanoid then
			humanoid:TakeDamage(damage)
		end
		CombatStateService.mark(player)
	end
	resultEvent:FireAllClients(player, result, attacker, if result == "Hit" then damage else 0)
	return result
end

local function onPlayerAdded(player: Player)
	-- Every new character starts with a clean defense.
	player.CharacterAdded:Connect(function()
		states[player] = newState()
		sendState(player, nil, nil)
	end)
end

function DefenseService:Start()
	Network.onReceive("RequestDodge", function()
		return true, nil
	end, dodge)
	Network.onReceive("RequestParry", function()
		return true, nil
	end, parry)

	-- DefenseState and DefenseEvent are server notices only. Listening and ignoring them avoids a
	-- queue of events with no handler if a client fires them.
	stateEvent.OnServerEvent:Connect(function() end)
	resultEvent.OnServerEvent:Connect(function() end)

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
end

return DefenseService
