--!strict
--[[
	Validate.luau
	Pure functions that check what arrives from the client (ADR-002, US-005). Each one returns
	`true`, or `false` and the reason, which the network layer shows in the Output warning.
	They accept any value: the client can send anything, including huge tables.
]]

local Validate = {}

-- A real number (neither NaN nor infinite) within [min, max].
function Validate.number(value: any, min: number, max: number): (boolean, string?)
	if typeof(value) ~= "number" then
		return false, `expected number, got {typeof(value)}`
	end
	if value ~= value or value == math.huge or value == -math.huge then
		return false, "invalid number (NaN or infinite)"
	end
	if value < min or value > max then
		return false, `number outside the range {min} to {max}`
	end
	return true, nil
end

-- A boolean.
function Validate.boolean(value: any): (boolean, string?)
	if typeof(value) ~= "boolean" then
		return false, `expected boolean, got {typeof(value)}`
	end
	return true, nil
end

-- A string that is one of the options (for example, an ability id).
function Validate.oneOf(value: any, options: { string }): (boolean, string?)
	if typeof(value) ~= "string" then
		return false, `expected string, got {typeof(value)}`
	end
	if not table.find(options, value) then
		return false, "unknown option"
	end
	return true, nil
end

-- A real Vector3 (no NaN or infinite components) whose length is within [min, max].
function Validate.vector(value: any, min: number, max: number): (boolean, string?)
	if typeof(value) ~= "Vector3" then
		return false, `expected Vector3, got {typeof(value)}`
	end
	for _, component in { value.X, value.Y, value.Z } do
		if component ~= component or component == math.huge or component == -math.huge then
			return false, "invalid vector (NaN or infinite)"
		end
	end
	local length = value.Magnitude
	if length < min or length > max then
		return false, `vector length outside the range {min} to {max}`
	end
	return true, nil
end

-- Nothing (nil) or an Instance. The caller checks class, tag and distance.
function Validate.instanceOrNil(value: any): (boolean, string?)
	if value == nil or typeof(value) == "Instance" then
		return true, nil
	end
	return false, `expected Instance or nil, got {typeof(value)}`
end

return table.freeze(Validate)
