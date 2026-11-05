--!strict
--[[
	EnergyService.luau
	Energia de cada jogador (US-012, aba Combate e Habilidades). O servidor é o dono do valor: as
	habilidades gastam com `gastar`, a energia volta sozinha com o tempo, e o valor vai para
	atributos do Player (Shared.Energia), que o HUD lê. Números em Config/Combate.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ConfigCombate = require(ReplicatedStorage.Shared.Config.Combate)
local Energia = require(ReplicatedStorage.Shared.Energia)

local EnergyService = {}

local energia: { [Player]: number } = {}

-- Publica o valor arredondado para baixo, para o HUD.
local function publicar(jogador: Player)
	local valor = energia[jogador]
	if valor then
		jogador:SetAttribute(Energia.ATRIBUTO, math.floor(valor))
	end
end

local function encher(jogador: Player)
	energia[jogador] = ConfigCombate.ENERGIA_MAX
	jogador:SetAttribute(Energia.ATRIBUTO_MAX, ConfigCombate.ENERGIA_MAX)
	publicar(jogador)
end

-- Provisório: todo personagem novo começa com a energia cheia.
local function aoEntrar(jogador: Player)
	encher(jogador)
	jogador.CharacterAdded:Connect(function()
		encher(jogador)
	end)
end

local function regenerar(dt: number)
	for jogador, valor in energia do
		if valor < ConfigCombate.ENERGIA_MAX then
			local novo = math.min(ConfigCombate.ENERGIA_MAX, valor + ConfigCombate.ENERGIA_REGEN * dt)
			energia[jogador] = novo
			if math.floor(novo) ~= math.floor(valor) then
				publicar(jogador)
			end
		end
	end
end

-- Tira `custo` da energia do jogador, se ele tiver o bastante. Devolve se gastou.
function EnergyService.gastar(jogador: Player, custo: number): boolean
	local atual = energia[jogador]
	if not atual or atual < custo then
		return false
	end
	energia[jogador] = atual - custo
	publicar(jogador)
	return true
end

function EnergyService:Start()
	Players.PlayerAdded:Connect(aoEntrar)
	for _, jogador in Players:GetPlayers() do
		aoEntrar(jogador)
	end
	Players.PlayerRemoving:Connect(function(jogador)
		energia[jogador] = nil
	end)
	RunService.Heartbeat:Connect(regenerar)
end

return EnergyService
