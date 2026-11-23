--!strict
--[[
	Abilities.luau
	Ability types and pure hit math (US-012, Combat and Abilities tab, ADR-009). The server uses this
	math to decide who was hit; the client uses the same math to warn before requesting and to draw
	the effect right away. Each ability's numbers live in the weapon's Config.
]]

-- How the ability aims (types from the Combat and Abilities tab): "Front" is the area in front, in
-- the aim direction; "Target" goes on the locked target; "Around" is the area around oneself;
-- "Ground" is a circle on the ground, under the locked target or ahead (US-022).
export type Shape = "Front" | "Target" | "Around" | "Ground"

-- Why the server rejected a request. The client turns it into text for the player.
export type RejectReason =
	"NoCharacter"
	| "OnCooldown"
	| "InvalidTarget"
	| "OutOfRange"
	| "NoLineOfSight"
	| "NoEnergy"
	| "NoWeapon"
	| "Stunned"

-- The fields are explained in Config/Longsword. Distances in studs, times in seconds.
export type Ability = {
	id: string,
	name: string,
	key: Enum.KeyCode,
	shape: Shape,
	range: number,
	width: number,
	radius: number,
	energyCost: number,
	cooldown: number,
	damage: number,
	resetOnKill: boolean,
}

local SHAPES = { "Front", "Target", "Around", "Ground" }
local NUMERIC_FIELDS = { "range", "width", "radius", "energyCost", "cooldown", "damage" }

local Abilities = {}

-- Checks the ability data of a Config and returns it typed. Stops with a clear message if a field
-- is wrong (for example, after a number was edited by hand).
function Abilities.validate(list: any, configName: string): { Ability }
	assert(typeof(list) == "table", `{configName}: expected a list of abilities`)
	local ids: { string } = {}
	for index, ability in list do
		local where = `{configName}[{index}]`
		assert(typeof(ability) == "table", `{where}: expected a table`)
		assert(typeof(ability.id) == "string", `{where}: id must be a string`)
		assert(not table.find(ids, ability.id), `{where}: duplicate id ({ability.id})`)
		table.insert(ids, ability.id)
		assert(typeof(ability.name) == "string", `{where}: name must be a string`)
		local key = ability.key
		assert(typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode, `{where}: key must be an Enum.KeyCode`)
		assert(table.find(SHAPES, ability.shape), `{where}: shape must be Front, Target, Around or Ground`)
		for _, field in NUMERIC_FIELDS do
			local value = ability[field]
			assert(typeof(value) == "number" and value >= 0, `{where}: {field} must be a number >= 0`)
		end
		assert(ability.shape ~= "Front" or ability.width > 0, `{where}: a Front ability needs a width`)
		assert(ability.shape ~= "Ground" or ability.radius > 0, `{where}: a Ground ability needs a radius`)
		assert(typeof(ability.resetOnKill) == "boolean", `{where}: resetOnKill must be a boolean`)
	end
	return list
end

-- The ability with this id, or nil.
function Abilities.byId(list: { Ability }, id: string): Ability?
	for _, ability in list do
		if ability.id == id then
			return ability
		end
	end
	return nil
end

-- The direction flattened onto the ground plane, with length 1. nil if it points almost straight
-- up or down.
function Abilities.flatDirection(direction: Vector3): Vector3?
	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude < 0.1 then
		return nil
	end
	return flat.Unit
end

-- Whether `point` is inside the area in front of `origin`, facing `forward` (flat, length 1): up to
-- `range` ahead and `width` from side to side. `margin` grows the area on every side (ADR-009), and
-- `maxHeight` is the largest height difference accepted.
function Abilities.isInFront(
	origin: Vector3,
	forward: Vector3,
	point: Vector3,
	range: number,
	width: number,
	margin: number,
	maxHeight: number
): boolean
	local offset = point - origin
	if math.abs(offset.Y) > maxHeight then
		return false
	end
	local ahead = offset.X * forward.X + offset.Z * forward.Z
	local sideways = math.abs(offset.X * forward.Z - offset.Z * forward.X)
	return ahead >= -margin and ahead <= range + margin and sideways <= width / 2 + margin
end

-- Whether `point` is inside a cone in front of `origin`: up to `range` away and at most half of
-- `coneAngle` degrees from `forward` (flat, length 1). Used by the basic attack's aim assist (US-023).
function Abilities.isInCone(
	origin: Vector3,
	forward: Vector3,
	point: Vector3,
	range: number,
	coneAngle: number,
	maxHeight: number
): boolean
	local offset = point - origin
	if math.abs(offset.Y) > maxHeight then
		return false
	end
	local flat = Vector3.new(offset.X, 0, offset.Z)
	local distance = flat.Magnitude
	if distance > range then
		return false
	end
	if distance < 0.5 then
		return true
	end
	return forward:Dot(flat.Unit) >= math.cos(math.rad(coneAngle / 2))
end

-- Whether `point` is within `radius` of `origin` on the ground plane, with the same margin and height.
function Abilities.isInRadius(
	origin: Vector3,
	point: Vector3,
	radius: number,
	margin: number,
	maxHeight: number
): boolean
	local offset = point - origin
	if math.abs(offset.Y) > maxHeight then
		return false
	end
	return Vector3.new(offset.X, 0, offset.Z).Magnitude <= radius + margin
end

return table.freeze(Abilities)
