--!strict
--[[
	Notices.luau
	The last short notice for the player ("Corte frontal: em recarga", "Esquiva: vulnerável"…),
	shared by the controllers that reject an action (US-012, US-013) and shown by the HUD.
	The texts the player reads are game text, so they stay in Portuguese.
]]

-- What the player reads for each reason. The server sends the reasons in Shared.Abilities and
-- Shared.Defense; "NoLockedTarget" only comes from the client.
local REASON_TEXT: { [string]: string } = {
	NoCharacter = "sem personagem",
	OnCooldown = "em recarga",
	InvalidTarget = "alvo inválido",
	OutOfRange = "fora de alcance",
	NoLineOfSight = "sem linha de visão",
	NoEnergy = "sem energia",
	NoLockedTarget = "trave um inimigo primeiro",
	Vulnerable = "vulnerável",
	BagFull = "mochila cheia",
	TooFar = "longe demais",
	NotYours = "ainda é de quem lutou",
	Stunned = "atordoado",
	InCombatBorder = "em combate, não dá para trocar de zona",
	Downed = "derrubado",
	Interrupted = "interrompido por dano",
	NoPvp = "só numa zona com PvP",
	InCombat = "em combate",
	GroupFull = "o grupo está cheio",
	AlreadyInGroup = "já está em outro grupo",
	InviteSent = "convite enviado",
}

local Notices = {}

local lastText: string? = nil
local lastTime = 0

-- Shows "<action name>: <reason text>".
function Notices.showReason(actionName: string, reason: string)
	lastText = `{actionName}: {REASON_TEXT[reason] or reason}`
	lastTime = os.clock()
end

-- The last notice and when it appeared (os.clock), or nil if there was none.
function Notices.last(): (string?, number)
	return lastText, lastTime
end

return table.freeze(Notices)
