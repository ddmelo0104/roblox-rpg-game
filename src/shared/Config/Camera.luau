--!strict
--[[
	Config/Camera.luau
	Câmera, modo combate (shift-lock) e trava de alvo (aba Câmera e Mira do doc de design).
	A aba diz "a definir no protótipo": estes são os valores iniciais do protótipo (US-008, US-009).
]]

return table.freeze({
	-- Zoom da rodinha do mouse, em studs. O máximo evita ver por cima de paredes no PvP.
	ZOOM_MIN = 6,
	ZOOM_MAX = 22,

	-- Câmera no ombro direito no modo combate (X para a direita, Y para cima), em studs.
	DESLOCAMENTO_OMBRO = Vector3.new(1.75, 0.5, 0),

	-- Altura, acima do centro do personagem, de onde saem a mira e a linha de visão da trava.
	ALTURA_FOCO = 1.5,

	-- Distância máxima, em studs, para travar e para manter a trava num alvo.
	ALCANCE_TRAVA = 60,

	-- Graus a partir do centro da câmera em que um alvo pode ser escolhido ao travar.
	ANGULO_TRAVA = 45,

	-- Segundos sem linha de visão até a trava soltar sozinha.
	TEMPO_SEM_VISAO_SOLTA = 1.5,

	-- Provisório: se a trava pega outros jogadores em PvP é uma pergunta aberta da aba.
	TRAVA_PEGA_JOGADORES = true,

	-- Teclas provisórias (pergunta aberta da aba). O botão do meio do mouse também trava e solta.
	TECLA_MODO_COMBATE = Enum.KeyCode.LeftControl,
	TECLA_TRAVAR = Enum.KeyCode.T,
	TECLA_TROCAR_ALVO = Enum.KeyCode.Tab,
})
