--!strict
--[[
	DungeonBuilder.luau
	Builds one dungeon instance from a layout (US-041): placeholder rooms in a row (a floor and walls
	with doorways) joined by corridors, a zone region over all of it with the zone of the entrance
	(its rules apply inside), a return point in the first room, and the enemy spawn points of each
	room, which never respawn. Rooms built in Studio will replace the placeholders later.
	The folder is returned unparented: the caller parents it, so every tagged part appears at once.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DungeonLayout = require(ReplicatedStorage.Shared.DungeonLayout)
local DungeonsConfig = require(ReplicatedStorage.Shared.Config.Dungeons)
local Enemies = require(ReplicatedStorage.Shared.Enemies)
local Zones = require(ReplicatedStorage.Shared.Zones)

export type Room = { kind: DungeonLayout.RoomKind, center: CFrame }
export type Built = {
	folder: Folder,
	region: BasePart,
	-- Where players appear when they come in.
	start: CFrame,
	rooms: { Room },
}

-- Visual only: the colors of the placeholder rooms.
local FLOOR_COLOR = Color3.fromRGB(70, 66, 60)
local WALL_COLOR = Color3.fromRGB(95, 88, 80)
local REGION_HEIGHT = 200

local DungeonBuilder = {}

local function newPart(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.Color = color
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function newMarker(parent: Instance, name: string, cframe: CFrame): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(1, 1, 1)
	part.CFrame = cframe
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Parent = parent
	return part
end

-- A wall across the room at `z` (its local front or back), with a doorway in the middle if `door`.
local function crossWall(parent: Instance, center: CFrame, z: number, door: boolean)
	local size = DungeonsConfig.ROOM_SIZE
	if not door then
		newPart(parent, "Wall", Vector3.new(size.X, size.Y, 2), center * CFrame.new(0, size.Y / 2, z), WALL_COLOR)
		return
	end
	local side = (size.X - DungeonsConfig.CORRIDOR_WIDTH) / 2
	local offset = DungeonsConfig.CORRIDOR_WIDTH / 2 + side / 2
	for _, sign in { -1, 1 } do
		newPart(
			parent,
			"Wall",
			Vector3.new(side, size.Y, 2),
			center * CFrame.new(sign * offset, size.Y / 2, z),
			WALL_COLOR
		)
	end
end

local function addSpawnPoints(parent: Instance, kind: DungeonLayout.RoomKind, center: CFrame, zone: Zones.Zone)
	local groups = (DungeonsConfig.ROOM_ENEMIES :: any)[kind]
	if not groups then
		return
	end
	for index, group in groups do
		local offset = CFrame.new((index - (#groups + 1) / 2) * 10, 1, -10)
		local point = newMarker(parent, "EnemySpawn", center * offset)
		point:SetAttribute("Enemy", group.kind)
		point:SetAttribute("Count", group.count)
		point:SetAttribute("Elite", group.elite)
		point:SetAttribute("Tier", zone.tier)
		point:SetAttribute("Zone", zone.kind)
		point:SetAttribute("Radius", 6)
		point:SetAttribute("Respawns", false)
		local enemyKind = Enemies.kind(group.kind)
		if enemyKind and enemyKind.rank then
			point:SetAttribute("DungeonRole", enemyKind.rank)
		end
		CollectionService:AddTag(point, Enemies.SPAWN_TAG)
	end
end

-- Builds the rooms of `layout` in a row from `origin` (toward its front), in the zone `zone`.
function DungeonBuilder.build(layout: DungeonLayout.Layout, origin: CFrame, zone: Zones.Zone, name: string): Built
	local folder = Instance.new("Folder")
	folder.Name = name
	local size = DungeonsConfig.ROOM_SIZE
	local step = size.Z + DungeonsConfig.CORRIDOR_LENGTH
	local rooms: { Room } = {}
	local count = #layout.rooms

	for index, kind in layout.rooms do
		local center = origin * CFrame.new(0, 0, -(index - 1) * step)
		local room = Instance.new("Folder")
		room.Name = `{index} {kind}`
		room.Parent = folder
		newPart(room, "Floor", Vector3.new(size.X, 2, size.Z), center * CFrame.new(0, -1, 0), FLOOR_COLOR)
		for _, sign in { -1, 1 } do
			newPart(
				room,
				"Wall",
				Vector3.new(2, size.Y, size.Z),
				center * CFrame.new(sign * size.X / 2, size.Y / 2, 0),
				WALL_COLOR
			)
		end
		crossWall(room, center, size.Z / 2, index > 1)
		crossWall(room, center, -size.Z / 2, index < count)
		if index < count then
			local corridor = center * CFrame.new(0, 0, -(size.Z / 2 + DungeonsConfig.CORRIDOR_LENGTH / 2))
			local width = DungeonsConfig.CORRIDOR_WIDTH
			newPart(
				room,
				"CorridorFloor",
				Vector3.new(width, 2, DungeonsConfig.CORRIDOR_LENGTH),
				corridor * CFrame.new(0, -1, 0),
				FLOOR_COLOR
			)
			for _, sign in { -1, 1 } do
				newPart(
					room,
					"CorridorWall",
					Vector3.new(2, size.Y, DungeonsConfig.CORRIDOR_LENGTH),
					corridor * CFrame.new(sign * width / 2, size.Y / 2, 0),
					WALL_COLOR
				)
			end
		end
		addSpawnPoints(room, kind, center, zone)
		table.insert(rooms, { kind = kind, center = center })
	end

	-- The zone region over the whole instance: the entrance zone's rules apply inside.
	local length = count * step
	local region = newMarker(folder, "Region", origin * CFrame.new(0, 0, -(length / 2 - step / 2)))
	region.Size = Vector3.new(size.X + 40, REGION_HEIGHT, length + 40)
	region:SetAttribute("Zone", zone.kind)
	region:SetAttribute("Tier", zone.tier)
	region:SetAttribute("ZoneName", `Dungeon · {zone.name}`)
	region:SetAttribute("Dungeon", true) -- not shown on the world map (US-044)
	CollectionService:AddTag(region, Zones.TAG)

	-- Giving up inside comes back at the first room.
	local back = newMarker(folder, "ReturnPoint", origin * CFrame.new(0, 1, size.Z / 4))
	CollectionService:AddTag(back, Zones.RETURN_TAG)

	return {
		folder = folder,
		region = region,
		start = origin * CFrame.new(0, 4, size.Z / 4),
		rooms = rooms,
	}
end

return table.freeze(DungeonBuilder)
