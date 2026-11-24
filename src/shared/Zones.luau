--!strict
--[[
	Zones.luau
	Pure rules of the zones (EP-007), for the server and the client:
	- which zone region a point is in (US-035): a region is a part with the "Zone" tag and the
	  attributes Zone (the kind: Blue, City, Yellow, Red or Black), Tier and ZoneName. A region is
	  the part's box, or, with the attribute Radius, a vertical cylinder of that radius around the
	  part, Height studs tall (US-056: circles can be bigger than a part can be). Regions with the
	  same ZoneId are parts of one zone, so a zone can have any shape;
	- where the server publishes each player's zone and their entry protection (attributes);
	- the recommended GS of a tier (Zones and Risk tab).
]]

local Workspace = game:GetService("Workspace")

local ZonesConfig = require(script.Parent.Config.Zones)

-- A zone a point can be in: its kind, tier, the name players see and its rules (Config/Zones).
export type Zone = { kind: string, tier: number, name: string, rules: any, region: BasePart?, id: string? }

local Zones = {}

-- CollectionService tag of the zone regions built in Studio.
Zones.TAG = "Zone"

-- CollectionService tag of the return points, where players come back (EP-009).
Zones.RETURN_TAG = "ReturnPoint"

-- Player attributes the server sets (US-035, US-037).
Zones.KIND_ATTRIBUTE = "ZoneKind"
Zones.TIER_ATTRIBUTE = "ZoneTier"
Zones.NAME_ATTRIBUTE = "ZoneName"
-- true while the player is inside a dungeon (its region has the attribute Dungeon), for the look
-- of the screen (US-053).
Zones.DUNGEON_ATTRIBUTE = "ZoneIsDungeon"
Zones.PROTECTED_UNTIL = "ProtectedUntil"

-- The rules of a zone kind, or of the default kind if it does not exist.
function Zones.rules(kind: string): any
	return ZonesConfig.KINDS[kind] or ZonesConfig.KINDS[ZonesConfig.DEFAULT_ZONE]
end

-- The zone of any place outside every region.
function Zones.default(): Zone
	local kind = ZonesConfig.DEFAULT_ZONE
	return { kind = kind, tier = ZonesConfig.DEFAULT_TIER, name = Zones.rules(kind).name, rules = Zones.rules(kind) }
end

-- The zone a region stands for, from its attributes.
function Zones.fromRegion(region: BasePart): Zone
	local kind = region:GetAttribute("Zone")
	local tier = region:GetAttribute("Tier")
	local name = region:GetAttribute("ZoneName")
	local id = region:GetAttribute("ZoneId")
	local validKind = if typeof(kind) == "string" and ZonesConfig.KINDS[kind] then kind else ZonesConfig.DEFAULT_ZONE
	return {
		kind = validKind,
		tier = if typeof(tier) == "number" then tier else ZonesConfig.DEFAULT_TIER,
		name = if typeof(name) == "string" then name else Zones.rules(validKind).name,
		rules = Zones.rules(validKind),
		region = region,
		id = if typeof(id) == "string" and id ~= "" then id else nil,
	}
end

-- Whether two zones are the same zone: parts of one zone share a ZoneId (US-056).
function Zones.same(a: Zone, b: Zone): boolean
	if a.id ~= nil and a.id == b.id then
		return true
	end
	return a.region == b.region
end

-- The radius of a round region (attribute Radius), or nil for a box.
function Zones.radiusOf(region: BasePart): number?
	local radius = region:GetAttribute("Radius")
	return if typeof(radius) == "number" and radius > 0 then radius else nil
end

-- The height of a round region (attribute Height; very tall without it).
local function heightOf(region: BasePart): number
	local height = region:GetAttribute("Height")
	return if typeof(height) == "number" and height > 0 then height else math.huge
end

-- The lowest and highest heights (Y) of a region.
function Zones.verticalSpan(region: BasePart): (number, number)
	if Zones.radiusOf(region) then
		local half = heightOf(region) / 2
		return region.Position.Y - half, region.Position.Y + half
	end
	local cframe, half = region.CFrame, region.Size / 2
	local extent = math.abs(cframe.XVector.Y) * half.X
		+ math.abs(cframe.YVector.Y) * half.Y
		+ math.abs(cframe.ZVector.Y) * half.Z
	return region.Position.Y - extent, region.Position.Y + extent
end

-- Whether `point` is inside `region`: its box (any rotation), or its circle.
function Zones.contains(region: BasePart, point: Vector3): boolean
	local radius = Zones.radiusOf(region)
	if radius then
		local offset = point - region.Position
		return offset.X * offset.X + offset.Z * offset.Z <= radius * radius
			and math.abs(offset.Y) <= heightOf(region) / 2
	end
	local localPoint = region.CFrame:PointToObjectSpace(point)
	local half = region.Size / 2
	return math.abs(localPoint.X) <= half.X and math.abs(localPoint.Y) <= half.Y and math.abs(localPoint.Z) <= half.Z
end

-- How big a region is, to pick the smallest of those holding a point.
local function volumeOf(region: BasePart): number
	local radius = Zones.radiusOf(region)
	if radius then
		local height = heightOf(region)
		return 4 * radius * radius * (if height == math.huge then 1e6 else height)
	end
	return region.Size.X * region.Size.Y * region.Size.Z
end

-- The zone of `point` among `regions`: the smallest region that holds it (so a zone inside another
-- wins), or the default zone.
function Zones.at(point: Vector3, regions: { BasePart }): Zone
	local best: BasePart? = nil
	local bestVolume = math.huge
	for _, region in regions do
		if Zones.contains(region, point) then
			local volume = volumeOf(region)
			if volume < bestVolume then
				best = region
				bestVolume = volume
			end
		end
	end
	return if best then Zones.fromRegion(best) else Zones.default()
end

-- Whether the player still has the protection of entering a PvP zone.
function Zones.isProtected(player: Player): boolean
	local untilTime = player:GetAttribute(Zones.PROTECTED_UNTIL)
	return typeof(untilTime) == "number" and Workspace:GetServerTimeNow() < untilTime
end

-- The GS the interface recommends for a zone of this tier.
function Zones.recommendedGearScore(tier: number): number
	return 100 * tier + 50
end

return table.freeze(Zones)
