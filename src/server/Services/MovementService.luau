--!strict
--[[
	MovementService.luau
	Corrida e pulo (US-010, aba Movimentação). O cliente só pede para correr ou parar; o servidor
	confere o pedido e decide a velocidade (ADR-002). Os números vêm de Config/Movimento.
	A conferência do deslocamento contra speed hack é a US-011.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigMovimento = require(ReplicatedStorage.Shared.Config.Movimento)
local Validar = require(ReplicatedStorage.Shared.Validar)
local Rede = require(script.Parent.Parent.Rede)

local MovementService = {}

-- O que o servidor decidiu para cada jogador. É a referência da US-011.
local correndo: { [Player]: boolean } = {}

local function humanoideDe(jogador: Player): Humanoid?
	local personagem = jogador.Character
	if not personagem then
		return nil
	end
	return personagem:FindFirstChildOfClass("Humanoid")
end

local function velocidadePermitida(jogador: Player): number
	if correndo[jogador] then
		return ConfigMovimento.VELOCIDADE_CORRIDA
	end
	return ConfigMovimento.VELOCIDADE_ANDAR
end

local function aplicarVelocidade(jogador: Player)
	local humanoide = humanoideDe(jogador)
	if humanoide then
		humanoide.WalkSpeed = velocidadePermitida(jogador)
	end
end

-- Todo personagem novo começa andando, com o pulo do Config.
local function prepararPersonagem(jogador: Player, personagem: Model)
	correndo[jogador] = false
	local humanoide = personagem:WaitForChild("Humanoid", 10)
	if humanoide and humanoide:IsA("Humanoid") then
		humanoide.UseJumpPower = false
		humanoide.JumpHeight = ConfigMovimento.ALTURA_PULO
		humanoide.WalkSpeed = ConfigMovimento.VELOCIDADE_ANDAR
	end
end

local function aoEntrar(jogador: Player)
	jogador.CharacterAdded:Connect(function(personagem)
		prepararPersonagem(jogador, personagem)
	end)
	local atual = jogador.Character
	if atual then
		task.spawn(prepararPersonagem, jogador, atual)
	end
end

-- A velocidade que o servidor permite agora para o jogador. Usada pela validação da US-011.
function MovementService.velocidadePermitida(jogador: Player): number
	return velocidadePermitida(jogador)
end

function MovementService:Start()
	Rede.aoReceber("RequestSprint", Validar.booleano, function(jogador: Player, querCorrer: boolean)
		correndo[jogador] = querCorrer
		aplicarVelocidade(jogador)
	end)

	Players.PlayerAdded:Connect(aoEntrar)
	for _, jogador in Players:GetPlayers() do
		aoEntrar(jogador)
	end
	Players.PlayerRemoving:Connect(function(jogador)
		correndo[jogador] = nil
	end)
end

return MovementService
