--!strict
--[[
	Main.client.luau
	Ponto de entrada do cliente. Confirma que o require de ReplicatedStorage.Shared
	também funciona do lado do cliente (US-003).
	Os Controllers (câmera, UI, efeitos) entram aqui conforme as histórias forem implementadas.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- No cliente, espera a replicação de ReplicatedStorage antes de usar os módulos compartilhados.
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Projeto = require(Shared:WaitForChild("Projeto") :: ModuleScript)

print(`[Main] cliente ok · {Projeto.descricao()} · {Players.LocalPlayer.Name}`)
