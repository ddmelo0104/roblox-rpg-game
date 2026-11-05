--!strict
--[[
	Rede.luau
	Camada de rede do servidor (US-005, ADR-002). Todo Remote que chega do cliente passa por
	Rede.aoReceber: primeiro o limite de pedidos por segundo, depois a validação do conteúdo.
	O que não passar é ignorado com um aviso no Output, sem erro.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigRede = require(ReplicatedStorage.Shared.Config.Rede)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

-- Confere os argumentos que vieram do cliente. Devolve se passou e, se não passou, o motivo.
export type Validador = (...any) -> (boolean, string?)

type Janela = {
	inicio: number,
	contagem: number,
}

local Rede = {}

-- Janela de 1 segundo por jogador e por Remote, para o limite de pedidos.
local janelas: { [Player]: { [string]: Janela } } = {}

Players.PlayerRemoving:Connect(function(jogador)
	janelas[jogador] = nil
end)

local function janelasDe(jogador: Player): { [string]: Janela }
	local existentes = janelas[jogador]
	if existentes then
		return existentes
	end
	local novas: { [string]: Janela } = {}
	janelas[jogador] = novas
	return novas
end

-- Conta o pedido e diz se ele ainda está dentro do limite. Avisa uma vez por janela.
local function dentroDoLimite(jogador: Player, nome: string): boolean
	local agora = os.clock()
	local doJogador = janelasDe(jogador)
	local janela = doJogador[nome]
	if not janela or agora - janela.inicio >= 1 then
		doJogador[nome] = { inicio = agora, contagem = 1 }
		return true
	end
	janela.contagem += 1
	if janela.contagem == ConfigRede.LIMITE_POR_SEGUNDO + 1 then
		warn(`[Rede] {nome}: {jogador.Name} passou de {ConfigRede.LIMITE_POR_SEGUNDO} pedidos por segundo`)
	end
	return janela.contagem <= ConfigRede.LIMITE_POR_SEGUNDO
end

-- Liga o Remote `nome` a uma função do servidor. `validar` recebe os argumentos do cliente e
-- confere tipo e faixa; `aoPedir` só roda se o pedido passar pelo limite e pela validação.
function Rede.aoReceber(nome: string, validar: Validador, aoPedir: (jogador: Player, ...any) -> ())
	Remotes.evento(nome).OnServerEvent:Connect(function(jogador: Player, ...: any)
		if not dentroDoLimite(jogador, nome) then
			return
		end
		local ok, motivo = validar(...)
		if not ok then
			warn(`[Rede] {nome} recusado de {jogador.Name}: {motivo or "conteúdo inválido"}`)
			return
		end
		aoPedir(jogador, ...)
	end)
end

return table.freeze(Rede)
