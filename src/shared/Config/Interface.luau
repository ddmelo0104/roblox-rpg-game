--!strict
--[[
	Config/Interface.luau
	Keys and colors of the interface screens (US-019, US-026). Provisional: the PC keys are an open
	question; I opens the inventory, as in Albion.
]]

return table.freeze({
	INVENTORY_KEY = Enum.KeyCode.I,

	-- Key of the prompts of chests and loot bags. Not E (the default), which is an ability key.
	INTERACT_KEY = Enum.KeyCode.G,

	-- Color of each rarity (Common … Legendary): item borders and the glow of loot bags (US-026).
	RARITY_COLORS = table.freeze({
		Color3.fromRGB(200, 200, 200),
		Color3.fromRGB(90, 200, 90),
		Color3.fromRGB(80, 150, 255),
		Color3.fromRGB(180, 90, 255),
		Color3.fromRGB(255, 160, 40),
	}),
})
