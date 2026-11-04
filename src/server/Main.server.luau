--!strict
--[[
	Main.server.luau
	Ponto de entrada do servidor. Por enquanto só confirma que o Rojo sincronizou o projeto
	e que o servidor consegue usar ReplicatedStorage.Shared (US-003).
	Os Services entram aqui, um por sistema, conforme as histórias forem implementadas.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Projeto = require(ReplicatedStorage.Shared.Projeto)

print(`[Main] servidor ok · {Projeto.descricao()}`)
