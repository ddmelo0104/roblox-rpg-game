--!strict
--[[
	Config/Combate.luau
	Energia e acerto das habilidades (aba Combate e Habilidades do doc de design). A aba diz "a
	definir no protótipo": estes são os valores iniciais da US-012, para ajustar jogando.
	Custo, cooldown, dano e alcance de cada habilidade ficam nos dados da arma (Config/EspadaLonga).
]]

return table.freeze({
	-- Energia máxima e quanto ela volta por segundo, em combate ou fora dele. Provisórios.
	ENERGIA_MAX = 100,
	ENERGIA_REGEN = 5,

	-- ADR-009 (proposto): studs a mais que o servidor aceita no alcance e na área, por causa do
	-- atraso da rede. O cliente confere sem essa margem antes de pedir.
	MARGEM_LAG = 1.5,

	-- Diferença máxima de altura, em studs, entre o centro de quem ataca e o de quem é atingido.
	ALTURA_ACERTO = 5,
})
