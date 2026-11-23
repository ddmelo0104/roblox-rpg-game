--!strict
--[[
	Config/Zones.luau
	The rules of each kind of zone (Zones and Risk tab), as data: the name and color players see, the
	loot's luck (US-026), the fame multiplier (US-029), whether players can fight each other (PvP,
	US-036), whether it is safe (the city: nobody takes damage there) and whether entering warns of
	full loot. A zone region in the world says its kind in the Zone attribute (US-035).
	In the M1 the Yellow zone has no PvP and the Red one has PvP for everyone (flags come in M2).
]]

-- Zone kind -> its rules. Typed with a string key, so a zone kind can be looked up by name.
local KINDS: { [string]: any } = {
	Blue = table.freeze({
		name = "Zona Azul",
		color = Color3.fromRGB(70, 140, 255),
		luck = 1,
		fame = 1,
		pvp = false,
		safe = false,
		risk = false,
		summary = "Sem PvP. Derrotado, você levanta.",
	}),
	City = table.freeze({
		name = "Cidade",
		color = Color3.fromRGB(235, 235, 235),
		luck = 1,
		fame = 1,
		pvp = false,
		safe = true,
		risk = false,
		summary = "Segura: ninguém toma dano aqui.",
	}),
	Yellow = table.freeze({
		name = "Zona Amarela",
		color = Color3.fromRGB(255, 210, 60),
		luck = 1.25,
		fame = 1.1,
		pvp = false,
		safe = false,
		risk = false,
		summary = "Sem PvP no M1. Derrotado, você levanta.",
	}),
	Red = table.freeze({
		name = "Zona Vermelha",
		color = Color3.fromRGB(230, 60, 60),
		luck = 1.75,
		fame = 1.3,
		pvp = true,
		safe = false,
		risk = true,
		summary = "PvP livre e saque total.",
	}),
	Black = table.freeze({
		name = "Zona Preta",
		color = Color3.fromRGB(60, 60, 60),
		luck = 2.5,
		fame = 1.5,
		pvp = true,
		safe = false,
		risk = true,
		summary = "Todos contra todos e saque total.",
	}),
}

return table.freeze({
	KINDS = table.freeze(KINDS),

	-- The zone of any place outside every zone region (and of a spawn point there).
	DEFAULT_ZONE = "Blue",
	DEFAULT_TIER = 1,

	-- Seconds of protection from other players after entering a PvP zone; attacking ends it (US-037).
	ENTRY_PROTECTION = 10,

	-- Seconds between two checks of the zone each player is in.
	ZONE_CHECK_INTERVAL = 0.25,

	-- Test layout (US-035): if the place has no zone region, these zones appear in a row to the left
	-- of the spawn, as in the M1 (Blue, city, Yellow, Red). `from` and `to` are studs to the left of
	-- the spawn (negative is to its right); `depth` is the size front to back.
	TEST_LAYOUT = table.freeze({
		depth = 700,
		height = 200,
		zones = table.freeze({
			table.freeze({ zone = "Blue", tier = 1, name = "Campos de Stardawn", from = -60, to = 250 }),
			table.freeze({ zone = "City", tier = 1, name = "Stardawn", from = 250, to = 400 }),
			table.freeze({ zone = "Yellow", tier = 2, name = "Colinas de Stardawn", from = 400, to = 650 }),
			table.freeze({ zone = "Red", tier = 3, name = "Picos de Stardawn", from = 650, to = 950 }),
		}),
	}),
})
