--!strict
--[[
	Remotes.luau
	Lista única dos Remotes do jogo (US-005). O servidor cria todos em ReplicatedStorage.Remotes
	antes de iniciar os Services; o cliente só espera por eles.

	Todo Remote é uma intenção do cliente ("quero correr") ou um aviso do servidor; o cliente
	nunca manda um resultado (ADR-002). Para um Remote novo: acrescente o nome em LISTA e valide
	o que chega dele no servidor com Rede.aoReceber.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NOME_PASTA = "Remotes"

-- Todos são RemoteEvent. RemoteFunction do servidor para o cliente fica proibida: o cliente pode
-- nunca responder e travar o servidor.
local LISTA: { string } = {
	"RequestPing", -- US-005: exemplo de pedido validado
	"RequestSprint", -- US-010: pedir para correr (true) ou parar (false)
}

local Remotes = {}

-- Só no servidor: cria a pasta e um RemoteEvent para cada nome da lista.
function Remotes.criar()
	assert(RunService:IsServer(), "Remotes.criar só roda no servidor")

	local pasta: Instance
	local existente = ReplicatedStorage:FindFirstChild(NOME_PASTA)
	if existente then
		pasta = existente
	else
		local nova = Instance.new("Folder")
		nova.Name = NOME_PASTA
		nova.Parent = ReplicatedStorage
		pasta = nova
	end

	for _, nome in LISTA do
		if not pasta:FindFirstChild(nome) then
			local evento = Instance.new("RemoteEvent")
			evento.Name = nome
			evento.Parent = pasta
		end
	end
end

-- Nos dois lados: o RemoteEvent pelo nome. No cliente, espera ele replicar.
function Remotes.evento(nome: string): RemoteEvent
	assert(table.find(LISTA, nome), `Remote desconhecido: {nome}`)
	local pasta = ReplicatedStorage:WaitForChild(NOME_PASTA)
	return pasta:WaitForChild(nome) :: RemoteEvent
end

return table.freeze(Remotes)
