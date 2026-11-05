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

-- Um texto que está na lista de opções (por exemplo, o id de uma habilidade).
function Validar.umDe(valor: any, opcoes: { string }): (boolean, string?)
	if typeof(valor) ~= "string" then
		return false, `esperava texto, veio {typeof(valor)}`
	end
	if not table.find(opcoes, valor) then
		return false, "opção desconhecida"
	end
	return true, nil
end

-- Um Vector3 de verdade (sem NaN nem infinito) com o tamanho dentro da faixa [minimo, maximo].
function Validar.vetor(valor: any, minimo: number, maximo: number): (boolean, string?)
	if typeof(valor) ~= "Vector3" then
		return false, `esperava Vector3, veio {typeof(valor)}`
	end
	for _, componente in { valor.X, valor.Y, valor.Z } do
		if componente ~= componente or componente == math.huge or componente == -math.huge then
			return false, "vetor inválido (NaN ou infinito)"
		end
	end
	local tamanho = valor.Magnitude
	if tamanho < minimo or tamanho > maximo then
		return false, `vetor com tamanho fora da faixa de {minimo} a {maximo}`
	end
	return true, nil
end

-- Nada (nil) ou uma Instance. Classe, tag e distância ficam para quem chama conferir.
function Validar.instanciaOuNada(valor: any): (boolean, string?)
	if valor == nil or typeof(valor) == "Instance" then
		return true, nil
	end
	return false, `esperava Instance ou nada, veio {typeof(valor)}`
end

return table.freeze(Validar)
