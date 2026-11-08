--!strict
--[[
	Loader.luau
	Starts the modules of a folder in two phases (US-007): first Init on all of them, then Start on
	all of them. Each call runs in a pcall, so an error in one module does not take down the others.
	The server Main uses it with the Services folder; the client Main, with the Controllers folder.

	Module contract: return a table with optional Init and Start, defined with `:`.
	- Init: sets up the module's own state. Must not yield or depend on another module being ready.
	- Start: connects events and starts working. Runs in its own thread, so it may yield.
]]

export type Module = {
	Init: ((self: any) -> ())?,
	Start: ((self: any) -> ())?,
}

type Loaded = {
	name: string,
	module: Module,
}

local Loader = {}

-- Requires the direct ModuleScript children of `folder`, in alphabetical order, and runs Init and
-- Start. Returns the names of the modules whose Init succeeded. `label` prefixes the warnings.
function Loader.start(folder: Instance?, label: string): { string }
	if not folder then
		return {}
	end

	local scripts: { ModuleScript } = {}
	for _, child in folder:GetChildren() do
		if child:IsA("ModuleScript") then
			table.insert(scripts, child)
		end
	end
	table.sort(scripts, function(a, b)
		return a.Name < b.Name
	end)

	local loaded: { Loaded } = {}
	for _, moduleScript in scripts do
		local ok, result = pcall(require, moduleScript)
		if not ok then
			warn(`[{label}] failed to load {moduleScript.Name}: {result}`)
		elseif typeof(result) ~= "table" then
			warn(`[{label}] {moduleScript.Name} did not return a table`)
		else
			table.insert(loaded, { name = moduleScript.Name, module = result :: Module })
		end
	end

	local initialized: { Loaded } = {}
	for _, item in loaded do
		local init = item.module.Init
		local ok: boolean, err: any = true, nil
		if init then
			ok, err = pcall(init, item.module)
		end
		if ok then
			table.insert(initialized, item)
		else
			warn(`[{label}] Init failed for {item.name}: {err}`)
		end
	end

	local names: { string } = {}
	for _, item in initialized do
		table.insert(names, item.name)
		local start = item.module.Start
		if start then
			task.spawn(function()
				local ok, err = pcall(start, item.module)
				if not ok then
					warn(`[{label}] Start failed for {item.name}: {err}`)
				end
			end)
		end
	end

	return names
end

return table.freeze(Loader)
