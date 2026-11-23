--!strict
--[[
	Config/Interface.luau
	Keys and colors of the interface screens (US-019, US-026). Provisional: the PC keys are an open
	question; I opens the inventory, as in Albion.
]]

return table.freeze({
	INVENTORY_KEY = Enum.KeyCode.I,

	-- Opens the mastery screen (US-032). M stays free for the map.
	MASTERY_KEY = Enum.KeyCode.N,

	-- Key of the prompts of chests, loot bags and reviving a downed player. Not E (the default),
	-- which is an ability key.
	INTERACT_KEY = Enum.KeyCode.G,

	-- Key of the prompt to finish a downed player (US-039), apart from reviving.
	FINISH_KEY = Enum.KeyCode.H,

	-- Starts or cancels channeling out of a dungeon (US-042).
	DUNGEON_EXIT_KEY = Enum.KeyCode.X,

	-- Color of each rarity (Common … Legendary): item borders and the glow of loot bags (US-026).
	RARITY_COLORS = table.freeze({
		Color3.fromRGB(200, 200, 200),
		Color3.fromRGB(90, 200, 90),
		Color3.fromRGB(80, 150, 255),
		Color3.fromRGB(180, 90, 255),
		Color3.fromRGB(255, 160, 40),
	}),
})
