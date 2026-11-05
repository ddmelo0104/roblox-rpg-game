--!strict
--[[
	Energia.luau
	Onde fica a energia de cada jogador (US-012). O servidor (EnergyService) é o dono do valor e o
	publica em atributos do Player; o cliente só lê, para a barra de energia e para avisar "sem
	energia" antes de pedir uma habilidade.
]]

local Energia = {}

Energia.ATRIBUTO = "Energia"
Energia.ATRIBUTO_MAX = "EnergiaMax"

-- A energia atual e a máxima do jogador, como o servidor publicou (0 e 0 enquanto não publicou).
function Energia.de(jogador: Player): (number, number)
	local atual = jogador:GetAttribute(Energia.ATRIBUTO)
	local maxima = jogador:GetAttribute(Energia.ATRIBUTO_MAX)
	return if typeof(atual) == "number" then atual else 0, if typeof(maxima) == "number" then maxima else 0
end

return table.freeze(Energia)
