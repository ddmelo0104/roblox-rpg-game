--!strict
--[[
	Habilidades.luau
	Tipos e contas puras das habilidades (US-012, aba Combate e Habilidades, ADR-009). O servidor
	usa estas contas para decidir quem foi atingido; o cliente usa as mesmas para avisar antes de
	pedir e para desenhar o efeito na hora. Os números de cada habilidade ficam no Config da arma.
]]

-- Como a habilidade mira (tipos da aba Combate e Habilidades): "Frente" é a área à frente, na
-- direção da mira; "Alvo" vai no alvo travado; "EmVolta" é a área em volta de si.
export type Forma = "Frente" | "Alvo" | "EmVolta"

-- Os campos estão explicados em Config/EspadaLonga. Distâncias em studs, tempos em segundos.
export type Habilidade = {
	id: string,
	nome: string,
	tecla: Enum.KeyCode,
	forma: Forma,
	alcance: number,
	largura: number,
	energia: number,
	recarga: number,
	dano: number,
	zeraAoDerrubar: boolean,
}

local FORMAS = { "Frente", "Alvo", "EmVolta" }
local CAMPOS_NUMERICOS = { "alcance", "largura", "energia", "recarga", "dano" }

local Habilidades = {}

-- Confere os dados de habilidades de um Config e devolve a lista tipada. Para com uma mensagem
-- clara se algum campo estiver errado (por exemplo, depois de ajustar um número à mão).
function Habilidades.conferir(lista: any, nomeDoConfig: string): { Habilidade }
	assert(typeof(lista) == "table", `{nomeDoConfig}: esperava uma lista de habilidades`)
	local ids: { string } = {}
	for indice, habilidade in lista do
		local onde = `{nomeDoConfig}[{indice}]`
		assert(typeof(habilidade) == "table", `{onde}: esperava uma tabela`)
		assert(typeof(habilidade.id) == "string", `{onde}: id precisa ser texto`)
		assert(not table.find(ids, habilidade.id), `{onde}: id repetido ({habilidade.id})`)
		table.insert(ids, habilidade.id)
		assert(typeof(habilidade.nome) == "string", `{onde}: nome precisa ser texto`)
		local tecla = habilidade.tecla
		assert(
			typeof(tecla) == "EnumItem" and tecla.EnumType == Enum.KeyCode,
			`{onde}: tecla precisa ser um Enum.KeyCode`
		)
		assert(table.find(FORMAS, habilidade.forma), `{onde}: forma precisa ser Frente, Alvo ou EmVolta`)
		for _, campo in CAMPOS_NUMERICOS do
			local valor = habilidade[campo]
			assert(typeof(valor) == "number" and valor >= 0, `{onde}: {campo} precisa ser um número >= 0`)
		end
		assert(habilidade.forma ~= "Frente" or habilidade.largura > 0, `{onde}: a Frente precisa de largura`)
		assert(typeof(habilidade.zeraAoDerrubar) == "boolean", `{onde}: zeraAoDerrubar precisa ser booleano`)
	end
	return lista
end

-- A habilidade com este id, ou nil.
function Habilidades.porId(lista: { Habilidade }, id: string): Habilidade?
	for _, habilidade in lista do
		if habilidade.id == id then
			return habilidade
		end
	end
	return nil
end

-- A direção só no plano do chão, com tamanho 1. nil se ela apontar quase reto para cima ou para baixo.
function Habilidades.direcaoNoPlano(direcao: Vector3): Vector3?
	local plana = Vector3.new(direcao.X, 0, direcao.Z)
	if plana.Magnitude < 0.1 then
		return nil
	end
	return plana.Unit
end

-- Se `ponto` está na área à frente de `origem`, na direção `frente` (no plano, com tamanho 1):
-- até `alcance` para a frente e `largura` de um lado ao outro. A `margem` aumenta a área em
-- todos os lados (ADR-009), e `altura` é a diferença máxima de altura aceita.
function Habilidades.naFrente(
	origem: Vector3,
	frente: Vector3,
	ponto: Vector3,
	alcance: number,
	largura: number,
	margem: number,
	altura: number
): boolean
	local relativo = ponto - origem
	if math.abs(relativo.Y) > altura then
		return false
	end
	local paraFrente = relativo.X * frente.X + relativo.Z * frente.Z
	local paraOLado = math.abs(relativo.X * frente.Z - relativo.Z * frente.X)
	return paraFrente >= -margem and paraFrente <= alcance + margem and paraOLado <= largura / 2 + margem
end

-- Se `ponto` está a até `raio` de `origem` no plano do chão, com a mesma margem e altura.
function Habilidades.noRaio(origem: Vector3, ponto: Vector3, raio: number, margem: number, altura: number): boolean
	local relativo = ponto - origem
	if math.abs(relativo.Y) > altura then
		return false
	end
	return Vector3.new(relativo.X, 0, relativo.Z).Magnitude <= raio + margem
end

return table.freeze(Habilidades)
