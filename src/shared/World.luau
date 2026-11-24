--!strict
--[[
	World.luau
	Tags and attributes of the provisional world built by code (EP-007: US-052 to US-054), for both
	sides. The server builds the city and the scenery only when the place has none: a version made
	or frozen in Studio carries these tags. The client animates the decor.
]]

local World = {}

-- A city's model (the provisional one, or one made or frozen in Studio). If the place has one, no
-- provisional city is built.
World.CITY_TAG = "CityModel"

-- The folder of the provisional scenery of the test layout. If the place has one, it is not built
-- again.
World.SCENERY_TAG = "Scenery"

-- A model or part that the client turns around its vertical axis, like the Star of the monument.
World.SPIN_TAG = "Spin"
-- Attribute of a Spin instance: degrees per second.
World.SPIN_SPEED = "SpinSpeed"
-- Attribute of a Spin instance: studs it floats up and down (0 or missing: none).
World.BOB_HEIGHT = "BobHeight"

return table.freeze(World)
