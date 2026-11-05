--!strict
--[[
	PingService.luau
	Exemplo do padrão de rede (US-005): o cliente pede um ping com um número, o servidor confere
	o pedido e responde com o mesmo número e a hora do servidor. Serve de modelo para todo
	Remote novo: definir em Shared.Remotes, validar aqui com Rede.aoReceber, responder ou agir.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ConfigRede = require(ReplicatedStorage.Shared.Config.Rede)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Validar = require(ReplicatedStorage.Shared.Validar)
local Rede = require(script.Parent.Parent.Rede)

local PingService = {}

function PingService:Start()
	local evento = Remotes.evento("RequestPing")

	Rede.aoReceber("RequestPing", function(valor)
		return Validar.numero(valor, -ConfigRede.PING_MAXIMO, ConfigRede.PING_MAXIMO)
	end, function(jogador, valor)
		evento:FireClient(jogador, valor, Workspace:GetServerTimeNow())
	end)
end

return PingService
