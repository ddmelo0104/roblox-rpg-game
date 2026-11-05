--!strict
--[[
	Loader.luau
	Inicia os módulos de uma pasta em duas fases (US-007): primeiro o Init de todos, depois o
	Start de todos. Cada chamada roda num pcall, então o erro de um módulo não derruba os outros.
	O Main do servidor usa com a pasta Services; o do cliente, com a pasta Controllers.

	Contrato de cada módulo: devolver uma tabela com Init e Start opcionais, definidos com `:`.
	- Init: prepara o próprio estado. Não deve esperar (yield) nem depender de outro módulo pronto.
	- Start: liga eventos e começa a trabalhar. Roda numa thread própria, então pode esperar.
]]

export type Modulo = {
	Init: ((self: any) -> ())?,
	Start: ((self: any) -> ())?,
}

type Carregado = {
	nome: string,
	modulo: Modulo,
}

local Loader = {}

-- Carrega os ModuleScripts filhos diretos de `pasta`, em ordem alfabética, e roda Init e Start.
-- Devolve os nomes dos módulos que passaram pelo Init sem erro. `rotulo` aparece nos avisos.
function Loader.iniciar(pasta: Instance?, rotulo: string): { string }
	if not pasta then
		return {}
	end

	local scripts: { ModuleScript } = {}
	for _, filho in pasta:GetChildren() do
		if filho:IsA("ModuleScript") then
			table.insert(scripts, filho)
		end
	end
	table.sort(scripts, function(a, b)
		return a.Name < b.Name
	end)

	local carregados: { Carregado } = {}
	for _, moduleScript in scripts do
		local ok, resultado = pcall(require, moduleScript)
		if not ok then
			warn(`[{rotulo}] erro ao carregar {moduleScript.Name}: {resultado}`)
		elseif typeof(resultado) ~= "table" then
			warn(`[{rotulo}] {moduleScript.Name} não devolveu uma tabela`)
		else
			table.insert(carregados, { nome = moduleScript.Name, modulo = resultado :: Modulo })
		end
	end

	local iniciados: { Carregado } = {}
	for _, item in carregados do
		local init = item.modulo.Init
		local ok: boolean, erro: any = true, nil
		if init then
			ok, erro = pcall(init, item.modulo)
		end
		if ok then
			table.insert(iniciados, item)
		else
			warn(`[{rotulo}] erro no Init de {item.nome}: {erro}`)
		end
	end

	local nomes: { string } = {}
	for _, item in iniciados do
		table.insert(nomes, item.nome)
		local start = item.modulo.Start
		if start then
			task.spawn(function()
				local ok, erro = pcall(start, item.modulo)
				if not ok then
					warn(`[{rotulo}] erro no Start de {item.nome}: {erro}`)
				end
			end)
		end
	end

	return nomes
end

return table.freeze(Loader)
