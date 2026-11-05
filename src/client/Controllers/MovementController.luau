--!strict
--[[
	MovementController.luau
	Corrida no PC (US-010): segurar a tecla de correr pede ao servidor para correr, e soltar pede
	para parar. A velocidade muda na hora no cliente (previsão), e o servidor decide: o valor dele
	é o que vale e é replicado para o personagem.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigMovimento = require(Shared:WaitForChild("Config"):WaitForChild("Movimento") :: ModuleScript)
local Remotes = require(Shared:WaitForChild("Remotes") :: ModuleScript)

local MovementController = {}

local jogador = Players.LocalPlayer
local correndo = false

local function humanoide(): Humanoid?
	local personagem = jogador.Character
	if not personagem then
		return nil
	end
	return personagem:FindFirstChildOfClass("Humanoid")
end

local function definirCorrida(evento: RemoteEvent, querCorrer: boolean)
	if correndo == querCorrer then
		return
	end
	correndo = querCorrer

	-- Previsão: muda já no cliente para não esperar a volta do servidor.
	local h = humanoide()
	if h then
		h.WalkSpeed = if querCorrer then ConfigMovimento.VELOCIDADE_CORRIDA else ConfigMovimento.VELOCIDADE_ANDAR
	end
	evento:FireServer(querCorrer)
end

function MovementController:Start()
	local evento = Remotes.evento("RequestSprint")

	UserInputService.InputBegan:Connect(function(input, processado)
		if not processado and input.KeyCode == ConfigMovimento.TECLA_CORRER then
			definirCorrida(evento, true)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == ConfigMovimento.TECLA_CORRER then
			definirCorrida(evento, false)
		end
	end)

	-- O servidor começa todo personagem novo andando.
	jogador.CharacterAdded:Connect(function()
		correndo = false
	end)
end

return MovementController
