--!strict
--[[
	Config/Ambience.luau
	Light and weather of Stardawn, and the look of each zone (US-053). The Mundo e Terreno tab asks
	for "lighting and Atmosphere per zone, to give each one its identity".
	- Stardawn is "the star city", so it stays at a fixed dawn in pink and gold, the city's colors
	  (Facções tab). The M1 has no day and night cycle (dev's decision, 2026-11-24). A fixed time
	  keeps the zone colors and the fights easy to read, and the Facções tab gives each region its
	  own light (Tenebrarum is almost always night).
	- Entering a zone tweens the player's screen to the zone's look. The Blue is clear, the city warm,
	  the Yellow golden, the Red dull and reddish, and dungeons are darker.
	The values are the dev's starting point, to be tuned in Studio.
]]

-- One zone's look: tint, saturation, contrast and brightness of the image (ColorCorrection), and the
-- density, haze and color of the Atmosphere.
export type Look = {
	tint: Color3,
	saturation: number,
	contrast: number,
	brightness: number,
	density: number,
	haze: number,
	color: Color3,
}

local ZONES: { [string]: Look } = {
	Blue = {
		tint = Color3.fromRGB(252, 250, 255),
		saturation = 0.08,
		contrast = 0.03,
		brightness = 0.02,
		density = 0.26,
		haze = 1.2,
		color = Color3.fromRGB(240, 225, 240),
	},
	City = {
		tint = Color3.fromRGB(255, 242, 238),
		saturation = 0.12,
		contrast = 0.03,
		brightness = 0.03,
		density = 0.28,
		haze = 1.5,
		color = Color3.fromRGB(255, 210, 225),
	},
	Yellow = {
		tint = Color3.fromRGB(255, 246, 222),
		saturation = 0,
		contrast = 0.04,
		brightness = 0.02,
		density = 0.32,
		haze = 2,
		color = Color3.fromRGB(255, 226, 176),
	},
	Red = {
		tint = Color3.fromRGB(255, 222, 218),
		saturation = -0.18,
		contrast = 0.1,
		brightness = -0.03,
		density = 0.4,
		haze = 2.6,
		color = Color3.fromRGB(205, 150, 150),
	},
	Black = {
		tint = Color3.fromRGB(220, 210, 230),
		saturation = -0.35,
		contrast = 0.14,
		brightness = -0.08,
		density = 0.5,
		haze = 3,
		color = Color3.fromRGB(120, 110, 130),
	},
}
for _, look in ZONES do
	table.freeze(look)
end

return table.freeze({
	-- The server applies this light when the game starts, unless Lighting has the attribute
	-- ManualLighting = true (light made by hand in Studio). The zone look still applies.
	APPLY_LIGHTING = true,
	MANUAL_ATTRIBUTE = "ManualLighting",

	-- Lighting properties: a dawn with the sun just above the mountains.
	LIGHTING = table.freeze({
		ClockTime = 7.4,
		GeographicLatitude = 35,
		Brightness = 2.6,
		ExposureCompensation = 0.1,
		Ambient = Color3.fromRGB(95, 80, 95),
		OutdoorAmbient = Color3.fromRGB(150, 125, 140),
		EnvironmentDiffuseScale = 0.7,
		EnvironmentSpecularScale = 0.6,
		GlobalShadows = true,
		ShadowSoftness = 0.25,
	}),
	-- Pink haze with a golden glow toward the sun.
	ATMOSPHERE = table.freeze({
		Density = 0.28,
		Offset = 0.2,
		Color = Color3.fromRGB(255, 210, 225),
		Decay = Color3.fromRGB(255, 175, 130),
		Glare = 0.5,
		Haze = 1.5,
	}),
	CLOUDS = table.freeze({ Cover = 0.55, Density = 0.6, Color = Color3.fromRGB(255, 225, 235) }),
	BLOOM = table.freeze({ Intensity = 0.6, Size = 28, Threshold = 1.6 }),
	SUN_RAYS = table.freeze({ Intensity = 0.08, Spread = 0.6 }),

	-- Seconds the change of look takes when the player changes zones.
	TRANSITION_TIME = 2.5,
	ZONES = table.freeze(ZONES),
	-- The look inside a dungeon, whatever its zone.
	DUNGEON = table.freeze({
		tint = Color3.fromRGB(230, 225, 255),
		saturation = -0.1,
		contrast = 0.12,
		brightness = -0.06,
		density = 0.45,
		haze = 0.8,
		color = Color3.fromRGB(150, 140, 170),
	}) :: Look,
})
