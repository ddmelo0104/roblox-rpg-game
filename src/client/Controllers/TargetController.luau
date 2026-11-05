--!strict
--[[
	TargetController.luau
	Trava de alvo (US-009, aba Câmera e Mira). Travar escolhe o alvo válido mais perto do centro
	da câmera e liga o modo combate; a tecla de trocar passa para outro alvo; travar de novo solta.
	A trava também solta sozinha quando o alvo morre, sai do alcance, fica sem linha de visão por
	um tempo ou quando o modo combate desliga.
	É só do cliente: o servidor sempre confere alvo, alcance e linha de visão nas habilidades (ADR-002).
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigCamera = require(Shared:WaitForChild("Config"):WaitForChild("Camera") :: ModuleScript)
local Alvos = require(Shared:WaitForChild("Alvos") :: ModuleScript)
local CameraController = require(script.Parent.CameraController)

-- Cor do contorno do alvo travado (só visual).
local COR_CONTORNO = Color3.fromRGB(255, 196, 0)

local TargetController = {}

local jogador = Players.LocalPlayer
local alvo: Model? = nil
local contorno: Highlight? = nil
local tempoSemVisao = 0

local function raizDoJogador(): BasePart?
	local personagem = jogador.Character
	if not personagem then
		return nil
	end
	local raiz = personagem:FindFirstChild("HumanoidRootPart")
	if raiz and raiz:IsA("BasePart") then
		return raiz
	end
	return nil
end

local function foco(raiz: BasePart): Vector3
	return raiz.Position + Vector3.new(0, ConfigCamera.ALTURA_FOCO, 0)
end

-- Os modelos que podem ser travados: os com a tag de alvo e, se o Config deixar, os outros jogadores.
local function candidatos(): { Model }
	local lista: { Model } = {}
	for _, instancia in CollectionService:GetTagged(Alvos.TAG) do
		if instancia:IsA("Model") then
			table.insert(lista, instancia)
		end
	end
	if ConfigCamera.TRAVA_PEGA_JOGADORES then
		for _, outro in Players:GetPlayers() do
			local personagem = outro.Character
			if outro ~= jogador and personagem then
				table.insert(lista, personagem)
			end
		end
	end
	return lista
end

local function temLinhaDeVisao(origem: Vector3, modelo: Model, destino: Vector3): boolean
	local ignorar: { Instance } = { modelo }
	local personagem = jogador.Character
	if personagem then
		table.insert(ignorar, personagem)
	end
	local parametros = RaycastParams.new()
	parametros.FilterType = Enum.RaycastFilterType.Exclude
	parametros.FilterDescendantsInstances = ignorar
	return Workspace:Raycast(origem, destino - origem, parametros) == nil
end

-- O alvo vivo, no alcance, dentro do ângulo da câmera e visível, mais perto do centro da tela.
local function melhorAlvo(exceto: Model?): Model?
	local raiz = raizDoJogador()
	local camera = Workspace.CurrentCamera
	if not raiz or not camera then
		return nil
	end
	local origem = foco(raiz)
	local olhar = camera.CFrame.LookVector
	local cosMinimo = math.cos(math.rad(ConfigCamera.ANGULO_TRAVA))
	local melhor: Model? = nil
	local melhorCos = -math.huge

	for _, modelo in candidatos() do
		local posicao = Alvos.posicao(modelo)
		if modelo == exceto or not posicao or not Alvos.vivo(modelo) then
			continue
		end
		local paraAlvo = posicao - origem
		local distancia = paraAlvo.Magnitude
		if distancia < 0.5 or distancia > ConfigCamera.ALCANCE_TRAVA then
			continue
		end
		local cosAngulo = olhar:Dot(paraAlvo.Unit)
		if cosAngulo > melhorCos and cosAngulo >= cosMinimo and temLinhaDeVisao(origem, modelo, posicao) then
			melhor = modelo
			melhorCos = cosAngulo
		end
	end
	return melhor
end

local function soltar()
	alvo = nil
	tempoSemVisao = 0
	if contorno then
		contorno:Destroy()
		contorno = nil
	end
	CameraController.definirAlvo(nil)
end

local function travar(modelo: Model)
	soltar()
	alvo = modelo

	local novo = Instance.new("Highlight")
	novo.FillTransparency = 0.85
	novo.OutlineColor = COR_CONTORNO
	novo.DepthMode = Enum.HighlightDepthMode.Occluded
	novo.Adornee = modelo
	novo.Parent = modelo
	contorno = novo

	CameraController.definirModoCombate(true)
	CameraController.definirAlvo(modelo)
end

-- A cada quadro, confere se a trava ainda vale.
local function conferirTrava(dt: number)
	local atual = alvo
	if not atual then
		return
	end
	local raiz = raizDoJogador()
	local posicao = Alvos.posicao(atual)
	if not CameraController.emModoCombate() or not raiz or not posicao or not Alvos.vivo(atual) then
		soltar()
		return
	end
	local origem = foco(raiz)
	if (posicao - origem).Magnitude > ConfigCamera.ALCANCE_TRAVA then
		soltar()
		return
	end
	if temLinhaDeVisao(origem, atual, posicao) then
		tempoSemVisao = 0
	else
		tempoSemVisao += dt
		if tempoSemVisao >= ConfigCamera.TEMPO_SEM_VISAO_SOLTA then
			soltar()
		end
	end
end

local function alternarTrava()
	if alvo then
		soltar()
		return
	end
	local escolhido = melhorAlvo(nil)
	if escolhido then
		travar(escolhido)
	end
end

local function trocarAlvo()
	local atual = alvo
	if not atual then
		return
	end
	local proximo = melhorAlvo(atual)
	if proximo then
		travar(proximo)
	end
end

function TargetController:Start()
	UserInputService.InputBegan:Connect(function(input, processado)
		if processado then
			return
		end
		if input.KeyCode == ConfigCamera.TECLA_TRAVAR or input.UserInputType == Enum.UserInputType.MouseButton3 then
			alternarTrava()
		elseif input.KeyCode == ConfigCamera.TECLA_TROCAR_ALVO then
			trocarAlvo()
		end
	end)

	RunService.Heartbeat:Connect(conferirTrava)
	jogador.CharacterAdded:Connect(soltar)
end

return TargetController
