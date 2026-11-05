--!strict
--[[
	Config/EspadaLonga.luau
	As 3 habilidades da espada longa do protótipo (US-012), como o Davi definiu em 05/11:
	1. Corte frontal: 1,5 m para a frente, com largura para acertar 3 inimigos lado a lado.
	2. Golpe no alvo: só no inimigo travado, com mais dano.
	3. Giro: em volta de si; o cooldown zera quando ele derruba um inimigo.
	O resto (custo, cooldown, dano, alcance do golpe, raio do giro e teclas) é provisório, para
	ajustar jogando. As distâncias estão em metros e viram studs aqui: no Roblox, 1 stud = 0,28 m.

	Campos de cada habilidade (o servidor confere todos ao iniciar, com Shared.Habilidades):
	- forma: "Frente" (área à frente, na direção da mira), "Alvo" (no alvo travado) ou "EmVolta"
	- alcance: comprimento da área (Frente), distância máxima até o alvo (Alvo) ou raio (EmVolta)
	- largura: de um lado ao outro da área; só vale na Frente (0 nas outras)
	- energia: custo; recarga: cooldown em segundos; dano: quanto tira de vida
	- zeraAoDerrubar: se a habilidade derrubar um inimigo, o cooldown zera na hora
]]

-- Studs em 1 metro.
local METRO = 1 / 0.28

local LISTA = {
	{
		id = "CorteFrontal",
		nome = "Corte frontal",
		tecla = Enum.KeyCode.Q,
		forma = "Frente",
		alcance = 1.5 * METRO, -- ≈ 5,4 studs
		largura = 2.25 * METRO, -- ≈ 8 studs: 3 inimigos lado a lado, com uns 4 studs entre os centros
		energia = 10,
		recarga = 2,
		dano = 100,
		zeraAoDerrubar = false,
	},
	{
		id = "GolpeNoAlvo",
		nome = "Golpe no alvo",
		tecla = Enum.KeyCode.E,
		forma = "Alvo",
		alcance = 1.5 * METRO, -- provisório: o mesmo alcance da espada
		largura = 0,
		energia = 20,
		recarga = 6,
		dano = 220,
		zeraAoDerrubar = false,
	},
	{
		id = "Giro",
		nome = "Giro",
		tecla = Enum.KeyCode.R,
		forma = "EmVolta",
		alcance = 1.5 * METRO, -- provisório: o raio é o alcance da espada
		largura = 0,
		energia = 25,
		recarga = 8,
		dano = 80,
		zeraAoDerrubar = true,
	},
}

for _, habilidade in LISTA do
	table.freeze(habilidade)
end

return table.freeze(LISTA)
