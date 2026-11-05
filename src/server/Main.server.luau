--!strict
--[[
	Main.server.luau
	Ponto de entrada do servidor. Cria os Remotes do projeto (US-005) e inicia todos os Services
	de ServerScriptService.Server.Services com o Loader (US-007).
	Um sistema novo no servidor é só um ModuleScript novo na pasta Services.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Loader = require(Shared.Loader)
local Projeto = require(Shared.Projeto)
local Remotes = require(Shared.Remotes)

-- Os Remotes existem antes de qualquer Service começar a ouvir.
Remotes.criar()

local pasta = (script.Parent :: Instance):FindFirstChild("Services")
local servicos = Loader.iniciar(pasta, "Main")

print(`[Main] servidor ok · {Projeto.descricao()} · services: {table.concat(servicos, ", ")}`)
