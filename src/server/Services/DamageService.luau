--!strict
--[[
	DamageService.luau
	Damage to combat targets (training dummies and enemies), with who dealt it (US-026). Every hit of
	a player on a target goes through `deal`: it takes the health and writes down how much health
	each player removed. When a target is knocked down, the listeners get those numbers, so
	EnemyService can give the kill to the players who earned it. An enemy that resets forgets them
	(`forget`), so the damage done to an enemy that could not fight back is worth nothing (US-025).
]]

local DamageService = {}

export type Contributions = { [Player]: number }
type DamagedListener = (target: Model, attacker: Player?, dealt: number) -> ()
type KnockdownListener = (target: Model, contributions: Contributions) -> ()

-- Health removed from each target by each player. Weak keys: a destroyed target is forgotten.
local ledgers: { [Model]: Contributions } = setmetatable({}, { __mode = "k" }) :: any
local damagedListeners: { DamagedListener } = {}
local knockdownListeners: { KnockdownListener } = {}

-- Takes `amount` of health from `target`. `attacker` is the player who dealt it, if any. Returns
-- whether this hit knocked the target down.
function DamageService.deal(target: Model, amount: number, attacker: Player?): boolean
	local humanoid = target:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or amount <= 0 then
		return false
	end
	local before = humanoid.Health
	humanoid:TakeDamage(amount)
	local dealt = before - humanoid.Health
	if attacker and dealt > 0 then
		local ledger = ledgers[target]
		if not ledger then
			ledger = {}
			ledgers[target] = ledger
		end
		ledger[attacker] = (ledger[attacker] or 0) + dealt
	end
	for _, listener in damagedListeners do
		task.spawn(listener, target, attacker, dealt)
	end
	if humanoid.Health > 0 then
		return false
	end
	local contributions = ledgers[target] or {}
	ledgers[target] = nil
	for _, listener in knockdownListeners do
		task.spawn(listener, target, contributions)
	end
	return true
end

-- Forgets who damaged `target` (an enemy that reset).
function DamageService.forget(target: Model)
	ledgers[target] = nil
end

-- Calls `listener` after every hit on a target (also hits that removed no health).
function DamageService.onDamaged(listener: DamagedListener)
	table.insert(damagedListeners, listener)
end

-- Calls `listener` when a hit knocks a target down, with the health each player removed from it.
function DamageService.onKnockedDown(listener: KnockdownListener)
	table.insert(knockdownListeners, listener)
end

return DamageService
