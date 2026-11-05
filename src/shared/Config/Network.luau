--!strict
--[[
	Config/Network.luau
	Limits of the server's network layer (US-005). The dev's starting values; raise them if a
	legitimate system needs more requests per second.
]]

return table.freeze({
	-- Requests per second accepted from one player on the same Remote; the excess is dropped with a
	-- warning.
	MAX_REQUESTS_PER_SECOND = 20,

	-- Largest number (in absolute value) accepted by RequestPing, the US-005 validation example.
	PING_MAX_VALUE = 1000000,
})
