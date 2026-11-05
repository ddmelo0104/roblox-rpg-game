--!strict
--[[
	Validar.luau
	Funções puras para conferir o que chega do cliente (ADR-002, US-005). Cada uma devolve
	`true`, ou `false` e o motivo, que a camada de rede mostra no aviso do Output.
	Valem para qualquer valor: o cliente pode mandar qualquer coisa, inclusive tabelas gigantes.
]]

local Validar = {}

-- Um número de verdade (nem NaN, nem infinito) dentro da faixa [minimo, maximo].
function Validar.numero(valor: any, minimo: number, maximo: number): (boolean, string?)
	if typeof(valor) ~= "number" then
		return false, `esperava número, veio {typeof(valor)}`
	end
	if valor ~= valor or valor == math.huge or valor == -math.huge then
		return false, "número inválido (NaN ou infinito)"
	end
	if valor < minimo or valor > maximo then
		return false, `número fora da faixa de {minimo} a {maximo}`
	end
	return true, nil
end

-- Um booleano.
function Validar.booleano(valor: any): (boolean, string?)
	if typeof(valor) ~= "boolean" then
		return false, `esperava booleano, veio {typeof(valor)}`
	end
	return true, nil
end

return table.freeze(Validar)
