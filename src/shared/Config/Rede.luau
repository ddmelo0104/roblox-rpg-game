--!strict
--[[
	Config/Rede.luau
	Limites da camada de rede do servidor (US-005). Valores iniciais do dev, a ajustar se um
	sistema legítimo precisar de mais pedidos por segundo.
]]

return table.freeze({
	-- Pedidos por segundo aceitos de um jogador num mesmo Remote; o excesso é ignorado com aviso.
	LIMITE_POR_SEGUNDO = 20,

	-- Maior número (em valor absoluto) aceito no RequestPing, o exemplo de validação da US-005.
	PING_MAXIMO = 1000000,
})
