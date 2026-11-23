--!strict
--[[
	GroupDungeonService.luau
	The group dungeon of the M1 test (US-048; Davi 2026-11-05: one group dungeon in Stardawn, made
	to be cloned to other areas later). For each part with the "GroupDungeonEntrance" tag it builds,
	once, fixed rooms (Config/Dungeons.GROUP_LAYOUT) far from the world, with the zone of the
	entrance, elite groups and bosses (GROUP_ROOM_ENEMIES) that come back after GROUP_RESPAWN_TIME.
	A portal at the entrance takes players in, and one in the first room takes them out. The
	mini-boss and the boss leave chests meant for 4 players, split among everyone inside. The test
	layout gets one entrance in the Yellow zone.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DungeonsConfig = require(ReplicatedStorage.Shared.Config.Dungeons)
local InterfaceConfig = require(ReplicatedStorage.Shared.Config.Interface)
local Zones = require(ReplicatedStorage.Shared.Zones)
local ZonesConfig = require(ReplicatedStorage.Shared.Config.Zones)
local DungeonBuilder = require(script.Parent.Parent.DungeonBuilder)
local SplitChest = require(script.Parent.Parent.SplitChest)
local Teleport = require(script.Parent.Parent.Teleport)
local EnemyService = require(script.Parent.EnemyService)
local ZoneService = require(script.Parent.ZoneService)

type GroupDungeon = { built: DungeonBuilder.Built, zone: Zones.Zone, exitTo: CFrame }

local ENTRANCE_TAG = "GroupDungeonEntrance"

-- Game text (Portuguese) and the portals' look.
local DUNGEON_NAME = "Dungeon de grupo"
local ENTER_TEXT = "Entrar na dungeon de grupo"
local LEAVE_TEXT = "Sair da dungeon"
local PORTAL_COLOR = Color3.fromRGB(255, 150, 60)
local PORTAL_REACH = 10

local GroupDungeonService = {}

local folder: Folder
local dungeons: { GroupDungeon } = {}

local function insideOf(dungeon: GroupDungeon): { Player }
	local list: { Player } = {}
	for _, player in Players:GetPlayers() do
		if ZoneService.zoneOf(player).region == dungeon.built.region then
			table.insert(list, player)
		end
	end
	return list
end

local function portal(cframe: CFrame, actionText: string, onUse: (player: Player) -> ())
	local part = Instance.new("Part")
	part.Name = "Portal"
	part.Size = Vector3.new(6, 9, 1)
	part.CFrame = cframe * CFrame.new(0, 4.5, 0)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Material = Enum.Material.Neon
	part.Transparency = 0.3
	part.Color = PORTAL_COLOR
	part.Parent = folder
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = DUNGEON_NAME
	prompt.KeyboardKeyCode = InterfaceConfig.INTERACT_KEY
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = PORTAL_REACH
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	prompt.Triggered:Connect(onUse)
end

local function build(entrance: BasePart)
	local index = #dungeons + 1
	local zone = ZoneService.zoneAt(entrance.Position)
	local origin =
		CFrame.new(DungeonsConfig.GROUP_ORIGIN + Vector3.new(0, 0, (index - 1) * DungeonsConfig.GROUP_SPACING))
	local layout = { seed = 0, rooms = table.clone(DungeonsConfig.GROUP_LAYOUT) :: any }
	local built = DungeonBuilder.build(layout, origin, zone, `GroupDungeon{index}`, {
		roomEnemies = DungeonsConfig.GROUP_ROOM_ENEMIES,
		respawnTime = DungeonsConfig.GROUP_RESPAWN_TIME,
	})
	local dungeon: GroupDungeon = { built = built, zone = zone, exitTo = entrance.CFrame * CFrame.new(0, 4, 8) }
	built.folder.Parent = folder
	table.insert(dungeons, dungeon)

	portal(entrance.CFrame, ENTER_TEXT, function(player)
		Teleport.move(player, built.start)
	end)
	portal(built.start * CFrame.new(0, -4, 12), LEAVE_TEXT, function(player)
		if ZoneService.zoneOf(player).region == built.region then
			Teleport.move(player, dungeon.exitTo)
		end
	end)
end

local function onKill(kill: EnemyService.Kill)
	local role = kill.point:GetAttribute("DungeonRole")
	if role ~= "MiniBoss" and role ~= "Boss" then
		return
	end
	for _, dungeon in dungeons do
		if kill.point:IsDescendantOf(dungeon.built.folder) then
			SplitChest.spawn({
				parent = dungeon.built.folder,
				cframe = CFrame.new(kill.position + Vector3.new(0, 1.5, 0)),
				count = if role == "Boss"
					then DungeonsConfig.GROUP_BOSS_CHEST_ITEMS
					else DungeonsConfig.GROUP_MINIBOSS_CHEST_ITEMS,
				zone = dungeon.zone,
				reach = DungeonsConfig.CHEST_REACH,
				canOpen = function(player)
					return ZoneService.zoneOf(player).region == dungeon.built.region
				end,
				sharers = function()
					return insideOf(dungeon)
				end,
			})
			return
		end
	end
end

-- The test entrance: in the Yellow test zone, behind the dungeon entrance.
local function createTestEntrance()
	local spawnLocation = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	local base = if spawnLocation and spawnLocation:IsA("BasePart") then spawnLocation.CFrame else CFrame.new()
	for _, spec in ZonesConfig.TEST_LAYOUT.zones do
		if spec.zone == "Yellow" then
			local point = Instance.new("Part")
			point.Name = `Entrada da dungeon de grupo ({spec.name})`
			point.Size = Vector3.new(2, 1, 2)
			point.CFrame = base * CFrame.new(-(spec.from + spec.to) / 2, 0, 160)
			point.Anchored = true
			point.CanCollide = false
			point.CanQuery = false
			point.Transparency = 1
			point.Parent = Workspace
			CollectionService:AddTag(point, ENTRANCE_TAG)
		end
	end
end

function GroupDungeonService:Init()
	folder = Instance.new("Folder")
	folder.Name = "GroupDungeons"
	folder.Parent = Workspace
end

function GroupDungeonService:Start()
	EnemyService.onKilled(onKill)
	if #CollectionService:GetTagged(ENTRANCE_TAG) == 0 and Workspace:FindFirstChild("ZoneTestLayout") then
		createTestEntrance()
	end
	for _, entrance in CollectionService:GetTagged(ENTRANCE_TAG) do
		if entrance:IsA("BasePart") then
			build(entrance)
		end
	end
end

return GroupDungeonService
