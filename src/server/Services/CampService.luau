--!strict
--[[
	CampService.luau
	Open-world camps for groups of 2 to 4 (US-047; Davi 2026-11-04: fixed on the map). A Folder or
	Model with the "Camp" tag holds enemy spawn points with Respawns = false (the camp brings them
	back) and, optionally, a part named "ChestAnchor". When every enemy of the camp is down, a chest
	appears for the players who earned kills there and their group members; it waits
	Config/Camps.CHEST_LIFETIME seconds, and the whole camp comes back RESPAWN_TIME seconds after it
	was cleared. The test layout gets a camp in the Yellow zone and one in the Red zone.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CampsConfig = require(ReplicatedStorage.Shared.Config.Camps)
local Enemies = require(ReplicatedStorage.Shared.Enemies)
local SplitChest = require(script.Parent.Parent.SplitChest)
local EnemyService = require(script.Parent.EnemyService)
local ZoneService = require(script.Parent.ZoneService)

type Camp = {
	root: Instance,
	points: { BasePart },
	anchor: CFrame,
	-- The players who earned kills in this round of the camp.
	fighters: { [Player]: boolean },
	cleared: boolean,
}

local CAMP_TAG = "Camp"

local CampService = {}

local camps: { Camp } = {}

local function pointsOf(root: Instance): { BasePart }
	local list: { BasePart } = {}
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("BasePart") and CollectionService:HasTag(descendant, Enemies.SPAWN_TAG) then
			table.insert(list, descendant)
		end
	end
	return list
end

local function addCamp(root: Instance)
	for _, camp in camps do
		if camp.root == root then
			return
		end
	end
	local points = pointsOf(root)
	if #points == 0 then
		return
	end
	local anchorPart = root:FindFirstChild("ChestAnchor", true)
	local anchor = if anchorPart and anchorPart:IsA("BasePart") then anchorPart.CFrame else points[1].CFrame
	table.insert(camps, { root = root, points = points, anchor = anchor, fighters = {}, cleared = false })
end

local function campOf(point: BasePart): Camp?
	for _, camp in camps do
		if table.find(camp.points, point) then
			return camp
		end
	end
	return nil
end

local function isCleared(camp: Camp): boolean
	for _, point in camp.points do
		if EnemyService.livingAt(point) > 0 then
			return false
		end
	end
	return true
end

local function onKill(kill: EnemyService.Kill)
	local camp = campOf(kill.point)
	if not camp or camp.cleared then
		return
	end
	for _, player in kill.credited do
		camp.fighters[player] = true
	end
	if not isCleared(camp) then
		return
	end
	camp.cleared = true
	local fighters = camp.fighters
	local chest = SplitChest.spawn({
		parent = camp.root,
		cframe = camp.anchor + Vector3.new(0, 2, 0),
		count = CampsConfig.CHEST_ITEMS,
		zone = ZoneService.zoneAt(camp.anchor.Position),
		reach = 12,
		canOpen = function(player)
			return fighters[player] == true
		end,
		sharers = function()
			local list: { Player } = {}
			for player in fighters do
				local character = player.Character
				local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
				if
					player.Parent
					and root
					and root:IsA("BasePart")
					and (root.Position - camp.anchor.Position).Magnitude <= CampsConfig.SHARE_RANGE
				then
					table.insert(list, player)
				end
			end
			return list
		end,
	})
	task.delay(CampsConfig.CHEST_LIFETIME, function()
		if chest.Parent then
			chest:Destroy()
		end
	end)
	task.delay(CampsConfig.RESPAWN_TIME, function()
		if not camp.root.Parent then
			return
		end
		camp.fighters = {}
		camp.cleared = false
		for _, point in camp.points do
			EnemyService.respawn(point)
		end
	end)
end

-- The test camps: in the Yellow and Red test zones, to the front of the enemy row.
local function createTestCamps()
	local spawnLocation = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	local base = if spawnLocation and spawnLocation:IsA("BasePart") then spawnLocation.CFrame else CFrame.new()
	for index, spec in CampsConfig.TEST_CAMPS do
		local folder = Instance.new("Folder")
		folder.Name = `TestCamp{index}`
		local center = base * CFrame.new(-spec.left, 0, spec.back)
		for groupIndex, group in CampsConfig.TEST_ENEMIES do
			local point = Instance.new("Part")
			point.Name = "EnemySpawn"
			point.Size = Vector3.new(1, 1, 1)
			point.CFrame = center * CFrame.new((groupIndex - 2) * 8, 0, 0)
			point:SetAttribute("Enemy", group.kind)
			point:SetAttribute("Count", group.count)
			point:SetAttribute("Elite", group.elite)
			point:SetAttribute("Respawns", false)
			point:SetAttribute("Radius", 4)
			point:SetAttribute("TestContent", true)
			point.Parent = folder
			CollectionService:AddTag(point, Enemies.SPAWN_TAG)
		end
		local anchor = Instance.new("Part")
		anchor.Name = "ChestAnchor"
		anchor.Size = Vector3.new(1, 1, 1)
		anchor.CFrame = center * CFrame.new(0, 0, 10)
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.Transparency = 1
		anchor.Parent = folder
		CollectionService:AddTag(folder, CAMP_TAG)
		folder.Parent = Workspace
	end
end

function CampService:Start()
	EnemyService.onKilled(onKill)
	CollectionService:GetInstanceAddedSignal(CAMP_TAG):Connect(addCamp)
	if #CollectionService:GetTagged(CAMP_TAG) == 0 and Workspace:FindFirstChild("ZoneTestLayout") then
		createTestCamps()
	end
	for _, root in CollectionService:GetTagged(CAMP_TAG) do
		addCamp(root) -- the added signal may be deferred: read them now too
	end
	Players.PlayerRemoving:Connect(function(player)
		for _, camp in camps do
			camp.fighters[player] = nil
		end
	end)
end

return CampService
