--!strict
--[[
	Main.client.luau
	Ponto de entrada do cliente. Espera os módulos compartilhados replicarem e inicia todos os
	Controllers de Client.Controllers com o Loader (US-007).
	Um sistema novo no cliente (câmera, UI, efeitos) é só um ModuleScript novo na pasta Controllers.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- No cliente, espera a replicação de ReplicatedStorage antes de usar os módulos compartilhados.
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Loader = require(Shared:WaitForChild("Loader") :: ModuleScript)
local Projeto = require(Shared:WaitForChild("Projeto") :: ModuleScript)

local pasta = (script.Parent :: Instance):FindFirstChild("Controllers")
local lista = table.concat(Loader.iniciar(pasta, "Main"), ", ")

print(`[Main] cliente ok · {Projeto.descricao()} · {Players.LocalPlayer.Name} · controllers: {lista}`)
