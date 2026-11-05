--!strict
--[[
	Config/Treino.luau
	Boneco de treino do protótipo (US-009). Valores iniciais do dev, a ajustar.
]]

return table.freeze({
	-- Vida do boneco. Alta de propósito, para testar habilidades por bastante tempo.
	VIDA_BONECO = 1000,

	-- Segundos até o boneco voltar depois de derrubado.
	TEMPO_VOLTAR_BONECO = 5,

	-- Distância, em studs, à frente do SpawnLocation (ou da origem, se não houver spawn).
	DISTANCIA_DO_SPAWN = 20,
})
