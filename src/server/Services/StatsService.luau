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
local InventoryService = require(script.Parent.InventoryService)

local StatsService = {}

local stats: { [Player]: Items.Stats } = {}

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
	end)
end

return StatsService
