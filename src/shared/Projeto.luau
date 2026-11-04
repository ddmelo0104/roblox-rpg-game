--!strict
--[[
	Projeto.luau
	Informações gerais do projeto, compartilhadas entre servidor e cliente.
	Também é o exemplo de ModuleScript em ReplicatedStorage.Shared usado pelos dois lados (US-003).
]]

local Projeto = {}

Projeto.NOME = "Projeto RPG" -- nome provisório, até o jogo ser batizado
Projeto.VERSAO = "0.0.1"

-- Texto curto para logs, ex.: "Projeto RPG v0.0.1".
function Projeto.descricao(): string
	return `{Projeto.NOME} v{Projeto.VERSAO}`
end

return Projeto
