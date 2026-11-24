--!strict
--[[
	ItemDetails.luau
	What the player reads about an item (US-050; Davi, 2026-11-23: "a very intuitive and detailed
	inventory"): the name in its rarity color; slot, armor type, line, tier and rarity; the GS, where
	it comes from and the difference to what is worn in the same slot; the durability; what the item
	gives (the weapon's attacks, the chest ability, the boots' dodge, the armor bonuses); and the
	mastery its tier needs. Also the character's attributes and kit for the inventory. Rich text,
	shared by the inventory and the loot window (US-051). The texts are game text, in Portuguese.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Items = require(Shared:WaitForChild("Items") :: ModuleScript)
local Mastery = require(Shared:WaitForChild("Mastery") :: ModuleScript)
local Weapons = require(Shared:WaitForChild("Weapons") :: ModuleScript)
local ArmorConfig = require(Config:WaitForChild("Armor") :: ModuleScript)
local CombatConfig = require(Config:WaitForChild("Combat") :: ModuleScript)
local InterfaceConfig = require(Config:WaitForChild("Interface") :: ModuleScript)
local ItemsConfig = require(Config:WaitForChild("Items") :: ModuleScript)
local ProgressionConfig = require(Config:WaitForChild("Progression") :: ModuleScript)

-- Meters in 1 stud: the design doc writes distances in meters, and so does the player's text.
local METERS_PER_STUD = 0.28

-- Colors of the rich text.
local GOOD_COLOR = "#78e678"
local BAD_COLOR = "#ff6e6e"
local WARN_COLOR = "#ffc850"
local DIM_COLOR = "#a5a5b4"
local KEY_COLOR = "#ffd75a"

local ARMOR_TYPE_NAMES: { [string]: string } = { Light = "leve", Medium = "média", Heavy = "pesada" }
local BONUS_ORDER = { "damage", "health", "resistance", "cooldownReduction" }
local BONUS_NAMES: { [string]: string } = {
	damage = "de dano",
	health = "de vida",
	resistance = "de resistência",
	cooldownReduction = "de recarga",
}
local BASIC_ATTACK_KEY = "Mouse esq."
local PARRY_KEY = "Mouse dir."

local ItemDetails = {}

local function escape(text: string): string
	local escaped = text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
	return escaped
end

local function colored(text: string, color: string): string
	return `<font color="{color}">{text}</font>`
end

local function keyLabel(key: string): string
	return `<font color="{KEY_COLOR}"><b>[{key}]</b></font>`
end

-- A number as the player reads it: whole, or with one decimal after a comma.
local function number(value: number): string
	local rounded = math.round(value)
	if math.abs(value - rounded) < 0.05 then
		return tostring(rounded)
	end
	local text = string.format("%.1f", value):gsub("%.", ",")
	return text
end

local function percent(fraction: number): string
	return `{number(fraction * 100)}%`
end

local function signedPercent(fraction: number): string
	return if fraction < 0 then `−{percent(-fraction)}` else `+{percent(fraction)}`
end

local function meters(studs: number): string
	return `{number(studs * METERS_PER_STUD)} m`
end

-- The color of a rarity (1 = Common … 5 = Legendary).
function ItemDetails.rarityColor(rarity: number): Color3
	return InterfaceConfig.RARITY_COLORS[rarity] or Color3.new(1, 1, 1)
end

-- The GS of an item for this player, with their specialization and mastery.
function ItemDetails.gearScore(record: any, progress: any): number
	local specialization, mastery = Mastery.levelsOf(progress)(record)
	return Items.itemGearScore(record, specialization, mastery)
end

-- How much more GS `record` has than what is worn in its slot (an empty slot counts 0), or nil when
-- it is the worn item itself or not in the catalog.
function ItemDetails.difference(record: any, progress: any, equipped: { [string]: any }): number?
	local definition = Items.definition(record.itemId)
	if not definition then
		return nil
	end
	local worn = equipped[definition.slot]
	if worn and worn.uid == record.uid then
		return nil
	end
	local wornGearScore = if worn then ItemDetails.gearScore(worn, progress) else 0
	return ItemDetails.gearScore(record, progress) - wornGearScore
end

local function differenceText(difference: number): string
	if math.abs(difference) < 0.5 then
		return colored("igual ao equipado", DIM_COLOR)
	elseif difference > 0 then
		return colored(`▲ +{number(difference)} sobre o equipado`, GOOD_COLOR)
	end
	return colored(`▼ −{number(-difference)} abaixo do equipado`, BAD_COLOR)
end

local function shapeText(ability: any): string
	if ability.shape == "Front" then
		return `área à frente ({meters(ability.range)} × {meters(ability.width)})`
	elseif ability.shape == "Target" then
		return `no alvo travado, até {meters(ability.range)}`
	elseif ability.shape == "Around" then
		return `ao seu redor, raio de {meters(ability.range)}`
	elseif ability.shape == "Ground" then
		return `área no chão de raio {meters(ability.radius)}, até {meters(ability.range)}`
	end
	return ""
end

local function addWeapon(kit: any, lines: { string })
	table.insert(lines, "")
	table.insert(lines, `<b>Ataques</b> {colored("(dano base; o GS aumenta)", DIM_COLOR)}`)
	table.insert(
		lines,
		colored(
			if kit.HIT_KIND == "Melee"
				then "Corpo a corpo: o alvo pode aparar ou esquivar."
				else "À distância: o alvo só escapa esquivando.",
			DIM_COLOR
		)
	)
	local basic = kit.BASIC_ATTACK
	table.insert(
		lines,
		`{keyLabel(BASIC_ATTACK_KEY)} Ataque básico: {number(basic.damage)} de dano a cada {number(basic.interval)} s, até {meters(
			basic.range
		)}, sem energia`
	)
	for _, ability in kit.ABILITIES do
		table.insert(
			lines,
			`{keyLabel(ability.key.Name)} <b>{escape(ability.name)}</b>: {number(ability.damage)} de dano, {shapeText(
				ability
			)}`
		)
		local cost = `{number(ability.energyCost)} de energia · recarga de {number(ability.cooldown)} s`
		if ability.resetOnKill then
			cost ..= " · a recarga zera quando derruba um inimigo"
		end
		table.insert(lines, colored(`      {cost}`, DIM_COLOR))
	end
end

local function chestEffect(ability: any): string
	if ability.effect == "RestoreEnergy" then
		return `recupera {number(ability.amount)} de energia`
	elseif ability.effect == "Heal" then
		return `cura {percent(ability.amount)} da vida máxima`
	elseif ability.effect == "Resistance" then
		return `+{percent(ability.amount)} de resistência por {number(ability.duration)} s`
	end
	return ""
end

local function addChestAbility(armorType: string, lines: { string })
	local ability = ArmorConfig.CHEST_ABILITIES[armorType]
	if not ability then
		return
	end
	table.insert(
		lines,
		`{keyLabel(ArmorConfig.CHEST_ABILITY_KEY.Name)} <b>{escape(ability.name)}</b>: {chestEffect(ability)}`
	)
	local cost = if ability.energyCost > 0 then `{number(ability.energyCost)} de energia` else "sem custo"
	table.insert(lines, colored(`      {cost} · recarga de {number(ability.cooldown)} s`, DIM_COLOR))
end

local function addDodge(armorType: string, lines: { string })
	local dodge = ArmorConfig.BOOTS_DODGES[armorType]
	if not dodge then
		return
	end
	table.insert(
		lines,
		`{keyLabel(CombatConfig.DODGE_KEY.Name)} <b>Esquiva {ARMOR_TYPE_NAMES[armorType] or ""}</b>: avança {meters(
			dodge.distance
		)}, invulnerável por {number(dodge.invulnerableTime)} s`
	)
	table.insert(lines, colored(`      sem custo · recarga de {number(dodge.cooldown)} s`, DIM_COLOR))
end

local function bonusText(bonuses: any): string
	local parts = {}
	for _, key in BONUS_ORDER do
		local value = bonuses[key]
		if value and value > 0 then
			local sign = if key == "cooldownReduction" then "−" else "+"
			table.insert(parts, `{sign}{percent(value)} {BONUS_NAMES[key]}`)
		end
	end
	return table.concat(parts, " · ")
end

-- Everything about an item, in rich text. `hint` says what a click does there ("Clique para equipar.").
function ItemDetails.describe(record: any, progress: any, equipped: { [string]: any }, hint: string?): string
	local definition = Items.definition(record.itemId)
	local rarityColor = `#{ItemDetails.rarityColor(record.rarity):ToHex()}`
	local name = if definition then definition.name else record.itemId
	local lines = { `<font size="20" color="{rarityColor}"><b>{escape(name)}</b></font>` }
	if not definition then
		table.insert(lines, colored("Item desconhecido.", DIM_COLOR))
		return table.concat(lines, "\n")
	end

	local kind = ItemsConfig.SLOT_NAMES[definition.slot] or definition.slot
	if definition.armorType then
		kind = `{kind} {ARMOR_TYPE_NAMES[definition.armorType] or ""}`
	end
	local lineName = Mastery.lineName(definition.line)
	local rarityName = ItemsConfig.RARITY_NAMES[record.rarity] or "?"
	table.insert(lines, `{kind} · {lineName} · <b>T{record.tier}</b> · {colored(rarityName, rarityColor)}`)

	-- The GS, the comparison with the worn item and where the GS comes from.
	local specialization, mastery = Mastery.levelsOf(progress)(record)
	local gearScore = Items.itemGearScore(record, specialization, mastery)
	local worn = equipped[definition.slot]
	local gearScoreLine = `<font size="17"><b>GS {number(gearScore)}</b></font>`
	local difference = ItemDetails.difference(record, progress, equipped)
	if difference then
		gearScoreLine ..= `   {differenceText(difference)}`
	elseif worn and worn.uid == record.uid then
		gearScoreLine ..= `   {colored("equipado", GOOD_COLOR)}`
	end
	table.insert(lines, gearScoreLine)
	if record.durability <= 0 then
		table.insert(lines, colored("Quebrado: não conta GS nem dá bônus até ser consertado.", BAD_COLOR))
	else
		local parts = {
			`T{record.tier} +{number(ProgressionConfig.GS_PER_TIER * record.tier)}`,
			`{rarityName} +{number(ProgressionConfig.GS_RARITY[record.rarity] or 0)}`,
			`especialização {specialization} (+{number(ProgressionConfig.GS_PER_SPEC_LEVEL * specialization)})`,
			`maestria {mastery} (+{number(ProgressionConfig.GS_PER_MASTERY_LEVEL * mastery)})`,
		}
		table.insert(lines, colored(table.concat(parts, " · "), DIM_COLOR))
	end
	local durabilityText = `Durabilidade {number(record.durability)}%`
	if record.durability <= 0 then
		durabilityText = colored(durabilityText, BAD_COLOR)
	elseif record.durability <= 25 then
		durabilityText = colored(`{durabilityText} (quase quebrando)`, WARN_COLOR)
	end
	table.insert(lines, durabilityText)

	-- What it gives.
	local kit = if definition.slot == "Weapon" then Weapons.kit(record.itemId) else nil
	if kit then
		addWeapon(kit, lines)
	end
	if definition.armorType then
		table.insert(lines, "")
		local bonuses = ItemsConfig.ARMOR_BONUSES[definition.armorType]
		if bonuses then
			table.insert(lines, `<b>Bônus da peça</b>: {bonusText(bonuses)}`)
		end
		if definition.slot == "Chest" then
			addChestAbility(definition.armorType, lines)
		elseif definition.slot == "Feet" then
			addDodge(definition.armorType, lines)
		end
	end

	-- The mastery its tier needs (US-031).
	local canWear, required = Mastery.canWear(progress, record)
	if required > 0 then
		table.insert(lines, "")
		local current = Mastery.mastery(progress, definition.line)
		if canWear then
			table.insert(lines, colored(`Requer maestria {required} em {lineName} (você tem {current}).`, DIM_COLOR))
		else
			table.insert(
				lines,
				colored(
					`🔒 Requer maestria {required} em {lineName} para usar; você tem {current}. Ganhe fama usando itens de {lineName} (tecla {InterfaceConfig.MASTERY_KEY.Name}).`,
					BAD_COLOR
				)
			)
		end
	end
	if hint then
		table.insert(lines, "")
		table.insert(lines, colored(hint, KEY_COLOR))
	end
	return table.concat(lines, "\n")
end

-- The attributes the equipment gives the character (US-050), in rich text, without the GS.
function ItemDetails.statsText(stats: any): string
	local cooldownCut = 1 - stats.cooldownMultiplier
	return table.concat({
		`Vida <b>{number(CombatConfig.BASE_HEALTH * stats.healthMultiplier)}</b>   Energia <b>{number(
			CombatConfig.MAX_ENERGY
		)}</b>`,
		`Dano <b>{signedPercent(stats.damageMultiplier - 1)}</b>   Resistência <b>{percent(stats.resistance)}</b>`,
		`Recarga <b>{if cooldownCut > 0 then `−{percent(cooldownCut)}` else "0%"}</b>`,
	}, "\n")
end

-- The keys of the kit the equipment gives now (US-050), in rich text.
function ItemDetails.kitText(equipped: { [string]: any }): string
	local lines = {}
	local weapon = equipped.Weapon
	local kit = if weapon then Weapons.kit(weapon.itemId) else nil
	if kit then
		local parts = { `{keyLabel(BASIC_ATTACK_KEY)} Ataque básico` }
		for _, ability in kit.ABILITIES do
			table.insert(parts, `{keyLabel(ability.key.Name)} {escape(ability.name)}`)
		end
		table.insert(lines, table.concat(parts, "\n"))
	else
		table.insert(lines, colored("Sem arma: sem ataques.", BAD_COLOR))
	end
	local chest = Items.chestAbilityOf(equipped)
	if chest then
		table.insert(lines, `{keyLabel(ArmorConfig.CHEST_ABILITY_KEY.Name)} {escape(chest.name)}`)
	end
	local feet = equipped.Feet
	local feetDefinition = if feet then Items.definition(feet.itemId) else nil
	local bootsType = if feetDefinition and feetDefinition.armorType
		then feetDefinition.armorType
		else ArmorConfig.DEFAULT_BOOTS
	table.insert(lines, `{keyLabel(CombatConfig.DODGE_KEY.Name)} Esquiva {ARMOR_TYPE_NAMES[bootsType] or ""}`)
	table.insert(lines, `{keyLabel(PARRY_KEY)} Aparar`)
	return table.concat(lines, "\n")
end

return table.freeze(ItemDetails)
