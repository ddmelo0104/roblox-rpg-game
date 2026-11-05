--!strict
--[[
	EnergyService.luau
	Each player's energy (US-012, Combat and Abilities tab). The server owns the value: abilities
	spend it through `spend`, it comes back by itself over time, and it is published as Player
	attributes (Shared.Energy), which the HUD reads. The numbers live in Config/Combat.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CombatConfig = require(ReplicatedStorage.Shared.Config.Combat)
local Energy = require(ReplicatedStorage.Shared.Energy)

local EnergyService = {}

local energy: { [Player]: number } = {}

-- Publishes the value rounded down, for the HUD.
local function publish(player: Player)
	local value = energy[player]
	if value then
		player:SetAttribute(Energy.ATTRIBUTE, math.floor(value))
	end
end

local function refill(player: Player)
	energy[player] = CombatConfig.MAX_ENERGY
	player:SetAttribute(Energy.MAX_ATTRIBUTE, CombatConfig.MAX_ENERGY)
	publish(player)
end

-- Provisional: every new character starts with full energy.
local function onPlayerAdded(player: Player)
	refill(player)
	player.CharacterAdded:Connect(function()
		refill(player)
	end)
end

local function regenerate(dt: number)
	for player, value in energy do
		if value < CombatConfig.MAX_ENERGY then
			local updated = math.min(CombatConfig.MAX_ENERGY, value + CombatConfig.ENERGY_REGEN * dt)
			energy[player] = updated
			if math.floor(updated) ~= math.floor(value) then
				publish(player)
			end
		end
	end
end

-- Takes `cost` from the player's energy if they have enough. Returns whether it was spent.
function EnergyService.spend(player: Player, cost: number): boolean
	local current = energy[player]
	if not current or current < cost then
		return false
	end
	energy[player] = current - cost
	publish(player)
	return true
end

function EnergyService:Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		energy[player] = nil
	end)
	RunService.Heartbeat:Connect(regenerate)
end

return EnergyService
