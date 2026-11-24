--!strict
--[[
	Weapons.luau
	The kit of each weapon (US-021): the basic attack and the 3 abilities that the equipped weapon
	gives. The data lives in one Config per weapon (Longsword, Bow, Crossbow, FireStaff); ability ids
	are unique across weapons, so an id alone says which ability it is. The server checks the kits on
	start (Abilities.validate) and only accepts abilities of the weapon the player wears.
]]

local Config = script.Parent:WaitForChild("Config")

-- Weapon item id (Config/Items) -> its kit module.
local KITS: { [string]: any } = {
	Longsword = require(Config:WaitForChild("Longsword") :: ModuleScript),
	Bow = require(Config:WaitForChild("Bow") :: ModuleScript),
	Crossbow = require(Config:WaitForChild("Crossbow") :: ModuleScript),
	FireStaff = require(Config:WaitForChild("FireStaff") :: ModuleScript),
}

local Weapons = {}

-- The kit ({ BASIC_ATTACK, ABILITIES }) of a weapon item, or nil (no weapon or no kit).
function Weapons.kit(weaponId: string?): any
	return if weaponId then KITS[weaponId] else nil
end

-- Every weapon id that has a kit, with its kit.
function Weapons.all(): { [string]: any }
	return KITS
end

-- The ability with this id in any kit, or nil.
function Weapons.abilityById(id: string): any
	for _, kit in KITS do
		for _, ability in kit.ABILITIES do
			if ability.id == id then
				return ability
			end
		end
	end
	return nil
end

return table.freeze(Weapons)
