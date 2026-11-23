--!strict
--[[
	StatsService.luau
	The attributes each character gets from its equipment (US-018): GS, damage, health, resistance
	and cooldown, from Shared.Items.characterStats. They are applied to the character's MaxHealth
	(keeping the health fraction) whenever the equipment or the character changes, published as the
	GearScore attribute for the HUD, and read by CombatService and DefenseService.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig = require(ReplicatedStorage.Shared.Config.Combat)
local Items = require(ReplicatedStorage.Shared.Items)
local ItemsConfig = require(ReplicatedStorage.Shared.Config.Items)
local Workspace = game:GetService("Workspace")
local InventoryService = require(script.Parent.InventoryService)

local StatsService = {}

local stats: { [Player]: Items.Stats } = {}

-- Temporary extra resistance (the heavy chest's Fortress, US-024): amount and server time it ends.
type Buff = { amount: number, endsAt: number }
local resistanceBuffs: { [Player]: Buff } = {}

-- Attributes of a player without equipment data yet.
local NEUTRAL: Items.Stats = {
	gearScore = 100,
	damageMultiplier = 1,
	healthMultiplier = 1,
	resistance = 0,
	cooldownMultiplier = 1,
}

-- The current attributes of the player's character.
function StatsService.of(player: Player): Items.Stats
	return stats[player] or NEUTRAL
end

-- The resistance right now: the equipment's plus a running buff, within the limit of Config/Items.
function StatsService.resistanceOf(player: Player): number
	local resistance = StatsService.of(player).resistance
	local buff = resistanceBuffs[player]
	if buff and Workspace:GetServerTimeNow() < buff.endsAt then
		resistance += buff.amount
	end
	return math.min(resistance, ItemsConfig.MAX_RESISTANCE)
end

-- Adds `amount` of resistance for `duration` seconds (a new buff replaces the running one).
function StatsService.addResistance(player: Player, amount: number, duration: number)
	resistanceBuffs[player] = { amount = amount, endsAt = Workspace:GetServerTimeNow() + duration }
end

-- Recomputes the attributes and applies the max health, keeping the same fraction of health.
local function refresh(player: Player)
	local current = Items.characterStats(InventoryService.equipped(player))
	stats[player] = current
	player:SetAttribute(Items.GEAR_SCORE_ATTRIBUTE, math.floor(current.gearScore + 0.5))

	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if humanoid and humanoid.Health > 0 then
		local fraction = if humanoid.MaxHealth > 0 then humanoid.Health / humanoid.MaxHealth else 1
		humanoid.MaxHealth = CombatConfig.BASE_HEALTH * current.healthMultiplier
		humanoid.Health = humanoid.MaxHealth * fraction
	end
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid", 10)
		refresh(player)
	end)
end

function StatsService:Start()
	InventoryService.onChanged(refresh)
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
		task.spawn(refresh, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		stats[player] = nil
		resistanceBuffs[player] = nil
	end)
end

return StatsService
