--!strict
--[[
	Run.luau
	The command that builds the world of Stardawn in Studio (US-055). In Studio, in Edit mode (not
	during Play), type in the command bar (View > Command Bar):

		require(game.ServerStorage.WorldTools.Run)()

	It takes a minute or two and prints its progress in the Output. Then save the place.
	It loads fresh copies of the generator, the world's shape and Config/World on every run, so the
	changes Rojo syncs count without restarting Studio (Studio keeps required modules in memory).
	The other modules it uses (Props, Build and the other Configs) are loaded once per Studio
	session.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- A fresh copy of a module: requiring the module itself would return what Studio kept in memory.
local function fresh(module: Instance): any
	assert(module:IsA("ModuleScript"), `{module:GetFullName()} is not a ModuleScript`)
	local copy = module:Clone()
	copy.Parent = module.Parent
	local ok, result = pcall(require, copy)
	copy:Destroy()
	if not ok then
		error(result, 0)
	end
	return result
end

return function()
	local config = fresh(ReplicatedStorage.Shared.Config.World)
	local shape = fresh(script.Parent.WorldShape)
	local generator = fresh(script.Parent.StardawnGenerator)
	generator.generate(config, shape)
end
