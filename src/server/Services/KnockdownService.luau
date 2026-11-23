--!strict
--[[
	KnockdownService.luau
	Knockdown, revive, finish, give up and full loot (EP-009, Zones and Risk tab). A hit that would
	kill a player knocks them down instead (DefenseService's lethal-hit handler):
	- Down (US-038): they cannot move or act, take no damage and enemies leave them alone, for the
	  zone's knockdownTime (Config/Zones). Then they get up with GET_UP_HEALTH of their health, and
	  every worn item loses DURABILITY_LOSS points of durability. Where nobody gets up alone (the
	  Black zone), they die instead, with a full loot.
	- Revive and finish (US-039): another player holds a prompt on the downed character, REVIVE_TIME
	  to revive (they get up now) or FINISH_TIME to finish, only in zones where players can finish.
	  Damage taken while holding interrupts it.
	- Give up (US-039): the downed player comes back now at the return point of their zone. If a
	  player knocked them down in a full-loot zone, giving up counts as being finished.
	- Full loot (US-040): every worn and carried item leaves the inventory in one step; each one is
	  destroyed with ITEM_DESTROY_CHANCE, the rest go to a loot bag with priority for whoever
	  finished them. The player dies, comes back at the nearest city and gets the restart kit.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local InterfaceConfig = require(ReplicatedStorage.Shared.Config.Interface)
local Knockdown = require(ReplicatedStorage.Shared.Knockdown)
local KnockdownConfig = require(ReplicatedStorage.Shared.Config.Knockdown)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Zones = require(ReplicatedStorage.Shared.Zones)
local Network = require(script.Parent.Parent.Network)
local DefenseService = require(script.Parent.DefenseService)
local InventoryService = require(script.Parent.InventoryService)
local LootBagService = require(script.Parent.LootBagService)
local MovementValidationService = require(script.Parent.MovementValidationService)
local ZoneService = require(script.Parent.ZoneService)

-- One knockdown: who caused it (a player, or nil for an enemy), the zone and its prompts.
type Down = {
	by: Player?,
	zone: Zones.Zone,
	prompts: { ProximityPrompt },
}

-- Game text (Portuguese).
local REVIVE_TEXT = "Reanimar"
local FINISH_TEXT = "Finalizar"
local DOWNED_OBJECT_TEXT = "Derrubado"
local NOTICE_NAME = "Derrubado"

local KnockdownService = {}

local random = Random.new()
local downs: { [Player]: Down } = {}
-- Where each player comes back on their next character (give up or full loot).
local comeBackAt: { [Player]: CFrame } = {}

local function partsOf(player: Player): (Humanoid?, BasePart?)
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return humanoid, if root and root:IsA("BasePart") then root else nil
end

local function notify(player: Player, reason: string)
	Remotes.event("Notice"):FireClient(player, NOTICE_NAME, reason)
end

-- Ends the knockdown state (prompts and attributes); the caller decides what comes next.
local function clear(player: Player, down: Down)
	for _, prompt in down.prompts do
		prompt:Destroy()
	end
	if downs[player] == down then
		downs[player] = nil
	end
	player:SetAttribute(Knockdown.DOWNED_UNTIL, nil)
	player:SetAttribute(Knockdown.GIVE_UP_LOSES, nil)
	player:SetAttribute(Knockdown.DIES_AT_END, nil)
end

local function getUp(player: Player)
	local down = downs[player]
	if not down then
		return
	end
	clear(player, down)
	local humanoid = partsOf(player)
	if humanoid and humanoid.Health > 0 then
		humanoid.PlatformStand = false
		humanoid.Health = humanoid.MaxHealth * KnockdownConfig.GET_UP_HEALTH
	end
	InventoryService.wearDown(player, KnockdownConfig.DURABILITY_LOSS)
end

-- The player dies and comes back at `cframe` (nil: wherever Roblox puts them).
local function die(player: Player, cframe: CFrame?)
	if cframe then
		comeBackAt[player] = cframe
	end
	local humanoid = partsOf(player)
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.Health = 0
	end
end

-- Full loot (US-040): everything leaves the inventory at once, a part is destroyed, the rest goes to
-- a bag for `killer` first; the player dies, comes back at the nearest city with the restart kit.
local function fullLoot(player: Player, killer: Player?)
	local down = downs[player]
	if down then
		clear(player, down)
	end
	local _, root = partsOf(player)
	local position = if root then root.Position else Vector3.zero

	local kept = {}
	for _, record in InventoryService.takeAll(player) do
		if random:NextNumber() >= KnockdownConfig.ITEM_DESTROY_CHANCE then
			table.insert(kept, record)
		end
	end
	LootBagService.drop(position, kept, if killer then { killer } else {})
	InventoryService.giveRestartKit(player)

	local city = ZoneService.returnPoint(position, function(zone)
		return zone.rules.safe == true
	end)
	die(player, city)
end

-- A hit would kill the player: they are knocked down instead (US-038).
local function knockDown(player: Player, attacker: Instance?)
	local humanoid, root = partsOf(player)
	if not humanoid or not root or downs[player] then
		return
	end
	humanoid.Health = 1
	humanoid.PlatformStand = true

	local zone = ZoneService.zoneOf(player)
	local by = if attacker then Players:GetPlayerFromCharacter(attacker) else nil
	local down: Down = { by = by, zone = zone, prompts = {} }
	downs[player] = down
	local endsAt = Workspace:GetServerTimeNow() + zone.rules.knockdownTime
	player:SetAttribute(Knockdown.DOWNED_UNTIL, endsAt)
	player:SetAttribute(Knockdown.GIVE_UP_LOSES, by ~= nil and zone.rules.fullLoot == true)
	player:SetAttribute(Knockdown.DIES_AT_END, zone.rules.getsUp ~= true)

	local function addPrompt(actionText: string, key: Enum.KeyCode, holdTime: number, onDone: (helper: Player) -> ())
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = actionText
		prompt.ObjectText = DOWNED_OBJECT_TEXT
		prompt.KeyboardKeyCode = key
		prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
		prompt.HoldDuration = holdTime
		prompt.MaxActivationDistance = KnockdownConfig.REACH
		prompt.RequiresLineOfSight = false
		prompt.Parent = root
		table.insert(down.prompts, prompt)
		prompt.Triggered:Connect(function(helper)
			if helper == player or downs[player] ~= down then
				return
			end
			-- Holding is interrupted by damage: the helper must not have been hit while holding.
			if DefenseService.secondsSinceDamaged(helper) < holdTime then
				notify(helper, "Interrupted")
				return
			end
			local _, helperRoot = partsOf(helper)
			if not helperRoot or (helperRoot.Position - root.Position).Magnitude > KnockdownConfig.REACH + 2 then
				notify(helper, "TooFar")
				return
			end
			onDone(helper)
		end)
	end

	addPrompt(REVIVE_TEXT, InterfaceConfig.INTERACT_KEY, KnockdownConfig.REVIVE_TIME, function()
		getUp(player)
	end)
	if zone.rules.finishable then
		addPrompt(FINISH_TEXT, InterfaceConfig.FINISH_KEY, KnockdownConfig.FINISH_TIME, function(finisher)
			-- Finishing is an attack: only where the finisher can fight (the victim is down, so their
			-- entry protection no longer matters).
			if ZoneService.zoneOf(finisher).rules.pvp ~= true then
				notify(finisher, "NoPvp")
				return
			end
			fullLoot(player, finisher)
		end)
	end

	task.delay(zone.rules.knockdownTime, function()
		if downs[player] ~= down then
			return
		end
		if zone.rules.getsUp then
			getUp(player)
		else
			fullLoot(player, by)
		end
	end)
end

-- The downed player gives up (US-039).
local function giveUp(player: Player)
	local down = downs[player]
	if not down then
		return
	end
	if down.by and down.zone.rules.fullLoot then
		fullLoot(player, down.by) -- giving up to a player in a full-loot zone counts as being finished
		return
	end
	clear(player, down)
	InventoryService.wearDown(player, KnockdownConfig.DURABILITY_LOSS)
	local _, root = partsOf(player)
	local here = if root then root.Position else Vector3.zero
	local region = down.zone.region
	die(
		player,
		ZoneService.returnPoint(here, function(zone)
			return zone.region == region
		end)
	)
end

-- Whether the player is down (the server's view).
function KnockdownService.isDowned(player: Player): boolean
	return downs[player] ~= nil
end

function KnockdownService:Init()
	DefenseService.setLethalHandler(knockDown)
end

function KnockdownService:Start()
	Network.onReceive("RequestGiveUp", function()
		return true, nil
	end, giveUp)

	local function onCharacter(player: Player, character: Model)
		local down = downs[player]
		if down then
			clear(player, down) -- the old character is gone
		end
		local cframe = comeBackAt[player]
		comeBackAt[player] = nil
		if cframe then
			character:WaitForChild("HumanoidRootPart", 10)
			MovementValidationService.teleport(player, cframe)
		end
	end
	local function watch(player: Player)
		player.CharacterAdded:Connect(function(character)
			onCharacter(player, character)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		downs[player] = nil
		comeBackAt[player] = nil
	end)
end

return KnockdownService
