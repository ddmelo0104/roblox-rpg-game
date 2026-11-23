--!strict
--[[
	Defense.luau
	Types and pure checks of the defense (US-013, Combat and Abilities tab). The dodge gives a short
	invulnerability, and the parry opens a short window that negates a melee hit. A defense still
	counts if it started up to a grace time after the hit, so the defender wins close calls caused by
	lag (the tab's proposal).
]]

export type Action = "Dodge" | "Parry"
export type Result = "Dodged" | "Parried" | "ParryMissed" | "Hit"
export type RejectReason = "NoCharacter" | "OnCooldown" | "Vulnerable"
export type HitKind = "Melee" | "Ranged"

local Defense = {}

-- Whether a defense active from `startsAt` to `endsAt` covers a hit at `hitTime`, counting a
-- defense that started up to `grace` seconds after the hit.
function Defense.covers(startsAt: number, endsAt: number, hitTime: number, grace: number): boolean
	return startsAt <= hitTime + grace and endsAt >= hitTime
end

return table.freeze(Defense)
