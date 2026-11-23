--!strict
--[[
	Config/Tutorial.luau
	The tutorial quest of the M1, in the Blue zone (US-045; Davi, 2026-11-05: "a simple tutorial
	quest, only for the M1"). Each step waits for an event the server sees, `count` times:
	- HitDummy: hitting a training dummy; Defend: dodging or parrying a hit; KillEnemy: earning an
	  enemy kill; Equip: equipping an item; EnterZone: entering a zone of the kind `zone`.
	The steps and the reward were decided by the dev under Davi's delegation (2026-11-23).
]]

return table.freeze({
	STEPS = table.freeze({
		table.freeze({ text = "Trave um boneco de treino (T) e acerte-o com Q, E ou R", event = "HitDummy", count = 1 }),
		table.freeze({
			text = "No boneco que ataca, esquive (F) ou apare (botão direito) um golpe",
			event = "Defend",
			count = 1,
		}),
		table.freeze({ text = "Derrote 3 bandidos, à esquerda do spawn", event = "KillEnemy", count = 3 }),
		table.freeze({ text = "Pegue um item no baú (G) e equipe-o no inventário (I)", event = "Equip", count = 1 }),
		table.freeze({ text = "Vá até a cidade de Stardawn", event = "EnterZone", zone = "City", count = 1 }),
	}),

	-- The reward: the weapon the player wears (or the longsword), T1, of this rarity (3 = Rare).
	REWARD_RARITY = 3,
	REWARD_FALLBACK_ITEM = "Longsword",
})
