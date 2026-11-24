--!strict
--[[
	FameController.luau
	The fame pop-up (US-032): every gain rises above the character as "+34 fama · Espada longa", and
	every level reached by the weapon or by a line shows up a moment later, as "Espada longa:
	especialização 5" or "Espadas: maestria 5 · libera T2". The armor pieces' own levels only show on
	the mastery screen, so a kill does not flood the screen. The server sends the gains
	(ProgressUpdate).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared:WaitForChild("Items") :: ModuleScript)
local Mastery = require(Shared:WaitForChild("Mastery") :: ModuleScript)
local ProgressionConfig = require(Shared:WaitForChild("Config"):WaitForChild("Progression") :: ModuleScript)
local Remotes = require(Shared:WaitForChild("Remotes") :: ModuleScript)
local CombatEffectsController = require(script.Parent.CombatEffectsController)

-- Visual only: colors and sizes of the pop-ups, and the wait between two level pop-ups.
local FAME_COLOR = Color3.fromRGB(255, 215, 90)
local LEVEL_COLOR = Color3.fromRGB(120, 230, 255)
local FAME_TEXT_SIZE = 18
local LEVEL_TEXT_SIZE = 22
local LEVEL_DELAY = 0.5

local FameController = {}

local player = Players.LocalPlayer

local function itemName(itemId: string): string
	local definition = Items.definition(itemId)
	return if definition then definition.name else itemId
end

-- The tier that mastery `level` unlocks, if it is exactly a tier's requirement (T2 and up).
local function unlockedTier(level: number): number?
	for tier, required in ProgressionConfig.TIER_MASTERY do
		if tier > 1 and required == level then
			return tier
		end
	end
	return nil
end

local function formatFame(amount: number): string
	return if amount < 10 then string.format("%.1f", amount) else tostring(math.floor(amount + 0.5))
end

local function onGain(gain: any)
	local character = player.Character
	if not character then
		return
	end
	local weaponId: string? = gain.weaponId
	local text = `+{formatFame(gain.amount)} fama`
	if weaponId then
		text ..= ` · {itemName(weaponId)}`
	end
	CombatEffectsController.showText(character, text, FAME_COLOR, FAME_TEXT_SIZE)

	local shown = 0
	for _, levelUp in gain.levelUps do
		local label: string? = nil
		if levelUp.kind == "Item" and levelUp.id == weaponId then
			label = `{itemName(levelUp.id)}: especialização {levelUp.level}`
		elseif levelUp.kind == "Line" then
			label = `{Mastery.lineName(levelUp.id)}: maestria {levelUp.level}`
			local tier = unlockedTier(levelUp.level)
			if tier then
				label ..= ` · libera T{tier}`
			end
		end
		if label then
			shown += 1
			task.delay(LEVEL_DELAY * shown, function()
				if character.Parent then
					CombatEffectsController.showText(character, label :: string, LEVEL_COLOR, LEVEL_TEXT_SIZE)
				end
			end)
		end
	end
end

function FameController:Start()
	Remotes.event("ProgressUpdate").OnClientEvent:Connect(function(_progress: any, gain: any)
		if gain then
			onGain(gain)
		end
	end)
end

return FameController
