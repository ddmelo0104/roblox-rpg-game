--!strict
--[[
	CameraController.luau
	Câmera do PC (US-009, aba Câmera e Mira): terceira pessoa com zoom limitado e o modo combate,
	um shift-lock do próprio jogo. No modo combate, o mouse fica preso no centro, a câmera vai
	para o ombro e o personagem vira para onde a câmera aponta. Com um alvo travado (definido pelo
	TargetController), a câmera e o personagem acompanham o alvo.
	Tudo aqui é visual: o servidor não confia na câmera nem na trava (ADR-002).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigCamera = require(Shared:WaitForChild("Config"):WaitForChild("Camera") :: ModuleScript)
local Alvos = require(Shared:WaitForChild("Alvos") :: ModuleScript)

local CameraController = {}

local jogador = Players.LocalPlayer
local modoCombate = false
local alvoTravado: Model? = nil

local function partes(): (Humanoid?, BasePart?)
	local personagem = jogador.Character
	if not personagem then
		return nil, nil
	end
	local humanoide = personagem:FindFirstChildOfClass("Humanoid")
	local raiz = personagem:FindFirstChild("HumanoidRootPart")
	if raiz and raiz:IsA("BasePart") then
		return humanoide, raiz
	end
	return humanoide, nil
end

-- Vira o personagem para uma direção, só no plano (giro em Y).
local function virarPara(raiz: BasePart, direcao: Vector3)
	local plana = Vector3.new(direcao.X, 0, direcao.Z)
	if plana.Magnitude > 0.01 then
		raiz.CFrame = CFrame.lookAt(raiz.Position, raiz.Position + plana.Unit)
	end
end

-- Com alvo: a câmera fica atrás do ombro, olhando para o alvo, na distância do zoom atual.
local function apontarParaAlvo(camera: Camera, raiz: BasePart, posicaoAlvo: Vector3)
	local foco = raiz.Position + Vector3.new(0, ConfigCamera.ALTURA_FOCO, 0)
	if (posicaoAlvo - foco).Magnitude < 1 then
		return
	end
	local distancia = (camera.CFrame.Position - camera.Focus.Position).Magnitude
	local ombro = ConfigCamera.DESLOCAMENTO_OMBRO
	local olhar = CFrame.lookAt(foco, posicaoAlvo)
	local posicaoCamera = (olhar * CFrame.new(ombro.X, ombro.Y, distancia)).Position
	camera.CFrame = CFrame.lookAt(posicaoCamera, posicaoAlvo)
end

-- Roda a cada quadro, logo depois da câmera padrão do Roblox.
local function aCadaQuadro()
	if not modoCombate then
		return
	end
	local humanoide, raiz = partes()
	local camera = Workspace.CurrentCamera
	if not humanoide or not raiz or not camera or humanoide.Health <= 0 then
		return
	end

	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	humanoide.AutoRotate = false
	humanoide.CameraOffset = ConfigCamera.DESLOCAMENTO_OMBRO

	local posicaoAlvo = if alvoTravado then Alvos.posicao(alvoTravado) else nil
	if posicaoAlvo then
		apontarParaAlvo(camera, raiz, posicaoAlvo)
		virarPara(raiz, posicaoAlvo - raiz.Position)
	else
		virarPara(raiz, camera.CFrame.LookVector)
	end
end

function CameraController.emModoCombate(): boolean
	return modoCombate
end

function CameraController.definirModoCombate(ligado: boolean)
	if modoCombate == ligado then
		return
	end
	modoCombate = ligado
	if not ligado then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		local humanoide = partes()
		if humanoide then
			humanoide.AutoRotate = true
			humanoide.CameraOffset = Vector3.zero
		end
	end
end

-- Chamado pelo TargetController: o Model ao travar, nil ao soltar.
function CameraController.definirAlvo(alvo: Model?)
	alvoTravado = alvo
end

function CameraController:Start()
	jogador.CameraMinZoomDistance = ConfigCamera.ZOOM_MIN
	jogador.CameraMaxZoomDistance = ConfigCamera.ZOOM_MAX

	UserInputService.InputBegan:Connect(function(input, processado)
		if not processado and input.KeyCode == ConfigCamera.TECLA_MODO_COMBATE then
			CameraController.definirModoCombate(not modoCombate)
		end
	end)

	RunService:BindToRenderStep("ModoCombate", Enum.RenderPriority.Camera.Value + 1, aCadaQuadro)
end

return CameraController
