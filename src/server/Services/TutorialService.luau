--!strict
--[[
	TutorialService.luau
	The tutorial quest of the M1 (US-045, Config/Tutorial): steps that teach the basics in the Blue
	zone. Each step waits for an event the other services report (a hit on a training dummy, a
	dodge or parry, an enemy kill, an equip, entering the city). The progress is a section of the
	saved profile, so a player who comes back goes on from where they stopped, and a finished
	tutorial never starts again. The client gets the current step (TutorialUpdate); finishing it
	gives a Rare version of the weapon the player wears.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local ItemsConfig = require(ReplicatedStorage.Shared.Config.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local TutorialConfig = require(ReplicatedStorage.Shared.Config.Tutorial)
local DamageService = require(script.Parent.DamageService)
local DefenseService = require(script.Parent.DefenseService)
local EnemyService = require(script.Parent.EnemyService)
local InventoryService = require(script.Parent.InventoryService)
local ProfileService = require(script.Parent.ProfileService)
local ZoneService = require(script.Parent.ZoneService)

-- A player's progress: the step they are on (1-based) and how many events it has seen.
type Progress = { step: number, count: number }

-- Game text (Portuguese).
local TUTORIAL_NAME = "Tutorial"

local TutorialService = {}

local progressOf: { [Player]: Progress } = {}
local updateEvent = Remotes.event("TutorialUpdate")

local STEPS = TutorialConfig.STEPS

local function send(player: Player, reward: string?)
	local progress = progressOf[player]
	if not progress then
		return
	end
	local step = STEPS[progress.step]
	updateEvent:FireClient(player, {
		index = progress.step,
		total = #STEPS,
		text = if step then step.text else nil,
		count = progress.count,
		needed = if step then step.count else 0,
		done = step == nil,
		reward = reward,
	})
end

local function giveReward(player: Player): string
	local weapon = InventoryService.equipped(player).Weapon
	local itemId = if weapon then weapon.itemId else TutorialConfig.REWARD_FALLBACK_ITEM
	local record = InventoryService.createItem(itemId, ItemsConfig.MIN_TIER, TutorialConfig.REWARD_RARITY)
	if not InventoryService.give(player, record) then
		Remotes.event("Notice"):FireClient(player, TUTORIAL_NAME, "BagFull")
	end
	return Items.displayName(record)
end

-- Something happened that a step may be waiting for.
local function report(player: Player, event: string, zoneKind: string?)
	local progress = progressOf[player]
	local step = if progress then STEPS[progress.step] else nil
	if not progress or not step or step.event ~= event then
		return
	end
	if step.zone and step.zone ~= zoneKind then
		return
	end
	progress.count += 1
	if progress.count < step.count then
		send(player, nil)
		return
	end
	progress.step += 1
	progress.count = 0
	local reward = if STEPS[progress.step] == nil then giveReward(player) else nil
	send(player, reward)
end

local function loadSection(player: Player, saved: any)
	local step = if type(saved) == "table" and type(saved.step) == "number" then saved.step else 1
	local count = if type(saved) == "table" and type(saved.count) == "number" then saved.count else 0
	progressOf[player] = { step = math.clamp(math.floor(step), 1, #STEPS + 1), count = math.max(0, count) }
	send(player, nil)
end

local function saveSection(player: Player): any
	return progressOf[player]
end

local function releaseSection(player: Player)
	progressOf[player] = nil
end

function TutorialService:Init()
	ProfileService.addSection("tutorial", loadSection, saveSection, releaseSection)
end

function TutorialService:Start()
	updateEvent.OnServerEvent:Connect(function() end) -- a server notice only

	DamageService.onDamaged(function(target, attacker)
		if attacker and target:GetAttribute("TrainingDummy") == true then
			report(attacker, "HitDummy")
		end
	end)
	DefenseService.onDefended(function(player)
		report(player, "Defend")
	end)
	EnemyService.onKilled(function(kill)
		for _, player in kill.credited do
			report(player, "KillEnemy")
		end
	end)
	InventoryService.onEquipped(function(player)
		report(player, "Equip")
	end)
	ZoneService.onZoneChanged(function(player, zone)
		report(player, "EnterZone", zone.kind)
	end)
end

return TutorialService
