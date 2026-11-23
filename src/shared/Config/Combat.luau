--!strict
--[[
	Config/Combat.luau
	Energy and ability hits (Combat and Abilities tab of the design doc). The tab says "to be defined
	in the prototype": these are US-012's starting values, to be tuned by playing. The cost, cooldown,
	damage and range of each ability live in the weapon data (Config/Longsword).
]]

return table.freeze({
	-- Max energy and how much comes back per second, in or out of combat (ENERGIA_MAX and
	-- ENERGIA_REGEN in the design doc). Provisional.
	MAX_ENERGY = 100,
	ENERGY_REGEN = 5,

	-- ADR-009 (proposed): extra studs the server accepts in range and area because of network lag
	-- (MARGEM_LAG in the design doc). The client checks without this margin before requesting.
	LAG_MARGIN = 1.5,

	-- Max height difference, in studs, between the attacker's center and the target's center.
	MAX_HIT_HEIGHT = 5,

	-- US-013: defense. Dodge and parry cost no energy: without energy, the defense remains (Combat tab).
	-- Dodge: a short dash with invulnerability. In the game the boots will define it; the prototype
	-- has one dodge only (ESQUIVA_INVULNERAVEL and ESQUIVA_COOLDOWN in the design doc). Provisional.
	DODGE_KEY = Enum.KeyCode.F,
	DODGE_DISTANCE = 12, -- studs
	DODGE_DURATION = 0.25, -- seconds the dash lasts
	DODGE_INVULNERABLE_TIME = 0.35, -- seconds
	DODGE_COOLDOWN = 2, -- seconds

	-- Parry: a short window that negates a melee hit (PARRY_JANELA in the design doc). A parry that
	-- catches no hit leaves the player vulnerable: no dodge or parry for PARRY_MISS_LOCKOUT seconds.
	-- Provisional.
	PARRY_INPUT = Enum.UserInputType.MouseButton2,
	PARRY_WINDOW = 0.3, -- seconds
	PARRY_MISS_LOCKOUT = 1, -- seconds

	-- A successful parry stuns the attacker for this many seconds (Davi, 2026-11-23).
	PARRY_STUN_TIME = 0.5,

	-- A defense still counts if it started up to this many seconds after the hit: the defender wins
	-- close calls caused by lag (proposal of the Combat tab).
	DEFENSE_GRACE = 0.1,

	-- US-015: a player is in combat for this many seconds after dealing or taking damage (TEMPO_COMBATE
	-- in the Zones and Risk tab).
	COMBAT_TIME = 15,
})
