--!strict
--[[
	Config/Movimento.luau
	Números e teclas de movimento (aba Movimentação do doc de design). A aba diz "a definir no
	protótipo": estes são os valores iniciais do protótipo (US-008, US-010), para ajustar jogando.
]]

return table.freeze({
	-- studs/s. Padrão do Roblox, como a aba Movimentação cita.
	VELOCIDADE_ANDAR = 16,

	-- studs/s. Provisório do protótipo.
	VELOCIDADE_CORRIDA = 24,

	-- studs. Padrão do Roblox; provisório do protótipo.
	ALTURA_PULO = 7.2,

	-- Segurar para correr. Provisória: as teclas do PC são uma pergunta aberta da aba.
	TECLA_CORRER = Enum.KeyCode.LeftShift,
})
