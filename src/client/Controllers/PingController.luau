--!strict
--[[
	PingController.luau
	Lado do cliente do exemplo de rede (US-005): ao entrar, manda um ping e mostra a resposta
	do servidor no Output.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes") :: ModuleScript)

local PingController = {}

function PingController:Start()
	local evento = Remotes.evento("RequestPing")

	evento.OnClientEvent:Connect(function(valor: number, horaDoServidor: number)
		print(`[Rede] ping ok · {valor} · hora do servidor {string.format("%.2f", horaDoServidor)}`)
	end)

	evento:FireServer(1)
end

return PingController
