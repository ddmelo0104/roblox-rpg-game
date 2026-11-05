--!strict
--[[
	CombatHudController.luau
	HUD mínimo do protótipo (US-012): a barra de energia, um quadro por habilidade com a tecla, o
	nome e o cooldown, e o último aviso ("Sem energia", "em recarga"…). A borda do quadro fica
	vermelha quando falta energia para a habilidade. A UI de verdade é do EP-011.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Energia = require(Shared:WaitForChild("Energia") :: ModuleScript)
local CombatController = require(script.Parent.CombatController)
local EspadaLonga = require(Shared:WaitForChild("Config"):WaitForChild("EspadaLonga") :: ModuleScript)

-- Só visual: tamanhos (em pixels), tempo do aviso na tela e cores.
local LADO_QUADRO = 64
local ESPACO = 8
local ALTURA_ENERGIA = 14
local TEMPO_AVISO = 1.5
local COR_FUNDO = Color3.fromRGB(25, 25, 30)
local COR_ENERGIA = Color3.fromRGB(80, 170, 255)
local COR_SEM_ENERGIA = Color3.fromRGB(220, 70, 70)
local COR_AVISO = Color3.fromRGB(255, 200, 120)

type Quadro = {
	id: string,
	recarga: number,
	energia: number,
	sombra: Frame,
	tempo: TextLabel,
	borda: UIStroke,
}

type Hud = {
	preenchimento: Frame,
	valorEnergia: TextLabel,
	aviso: TextLabel,
	quadros: { Quadro },
}

local CombatHudController = {}

local jogador = Players.LocalPlayer

local function novoTexto(nome: string, tamanho: number, pai: Instance): TextLabel
	local texto = Instance.new("TextLabel")
	texto.Name = nome
	texto.BackgroundTransparency = 1
	texto.TextColor3 = Color3.new(1, 1, 1)
	texto.TextSize = tamanho
	texto.Text = ""
	texto.Parent = pai
	return texto
end

local function novoQuadro(habilidade: any, indice: number, pai: Instance): Quadro
	local fundo = Instance.new("Frame")
	fundo.Name = habilidade.id
	fundo.Size = UDim2.fromOffset(LADO_QUADRO, LADO_QUADRO)
	fundo.Position = UDim2.fromOffset((indice - 1) * (LADO_QUADRO + ESPACO), ALTURA_ENERGIA + ESPACO)
	fundo.BackgroundColor3 = COR_FUNDO
	fundo.BorderSizePixel = 0
	fundo.Parent = pai

	local borda = Instance.new("UIStroke")
	borda.Thickness = 2
	borda.Color = COR_FUNDO
	borda.Parent = fundo

	local tecla = novoTexto("Tecla", 14, fundo)
	tecla.Text = habilidade.tecla.Name
	tecla.TextXAlignment = Enum.TextXAlignment.Left
	tecla.Size = UDim2.fromOffset(24, 18)
	tecla.Position = UDim2.fromOffset(4, 2)

	local nome = novoTexto("Nome", 11, fundo)
	nome.Text = habilidade.nome
	nome.TextWrapped = true
	nome.Size = UDim2.new(1, -4, 0, 28)
	nome.Position = UDim2.new(0, 2, 1, -30)

	-- A sombra cobre o quadro e desce conforme o cooldown acaba.
	local sombra = Instance.new("Frame")
	sombra.Name = "Recarga"
	sombra.AnchorPoint = Vector2.new(0, 1)
	sombra.Position = UDim2.fromScale(0, 1)
	sombra.Size = UDim2.fromScale(1, 0)
	sombra.BackgroundColor3 = Color3.new(0, 0, 0)
	sombra.BackgroundTransparency = 0.35
	sombra.BorderSizePixel = 0
	sombra.ZIndex = 2
	sombra.Parent = fundo

	local tempo = novoTexto("Tempo", 20, fundo)
	tempo.Size = UDim2.fromScale(1, 1)
	tempo.ZIndex = 3

	return {
		id = habilidade.id,
		recarga = habilidade.recarga,
		energia = habilidade.energia,
		sombra = sombra,
		tempo = tempo,
		borda = borda,
	}
end

local function criarHud(): Hud
	local gui = Instance.new("ScreenGui")
	gui.Name = "HudDeCombate"
	gui.ResetOnSpawn = false

	local quantidade = #EspadaLonga
	local barra = Instance.new("Frame")
	barra.Name = "Barra"
	barra.AnchorPoint = Vector2.new(0.5, 1)
	barra.Position = UDim2.new(0.5, 0, 1, -20)
	barra.Size =
		UDim2.fromOffset(quantidade * LADO_QUADRO + (quantidade - 1) * ESPACO, ALTURA_ENERGIA + ESPACO + LADO_QUADRO)
	barra.BackgroundTransparency = 1
	barra.Parent = gui

	local fundoEnergia = Instance.new("Frame")
	fundoEnergia.Name = "Energia"
	fundoEnergia.Size = UDim2.new(1, 0, 0, ALTURA_ENERGIA)
	fundoEnergia.BackgroundColor3 = COR_FUNDO
	fundoEnergia.BorderSizePixel = 0
	fundoEnergia.Parent = barra

	local preenchimento = Instance.new("Frame")
	preenchimento.Name = "Preenchimento"
	preenchimento.Size = UDim2.fromScale(1, 1)
	preenchimento.BackgroundColor3 = COR_ENERGIA
	preenchimento.BorderSizePixel = 0
	preenchimento.Parent = fundoEnergia

	local valorEnergia = novoTexto("Valor", 12, fundoEnergia)
	valorEnergia.Size = UDim2.fromScale(1, 1)
	valorEnergia.ZIndex = 2

	local aviso = novoTexto("Aviso", 18, barra)
	aviso.AnchorPoint = Vector2.new(0.5, 1)
	aviso.Position = UDim2.new(0.5, 0, 0, -6)
	aviso.Size = UDim2.fromOffset(360, 22)
	aviso.TextColor3 = COR_AVISO
	aviso.TextStrokeTransparency = 0.5

	local quadros: { Quadro } = {}
	for indice, habilidade in EspadaLonga do
		table.insert(quadros, novoQuadro(habilidade, indice, barra))
	end

	gui.Parent = jogador:WaitForChild("PlayerGui")
	return {
		preenchimento = preenchimento,
		valorEnergia = valorEnergia,
		aviso = aviso,
		quadros = quadros,
	}
end

local function atualizar(hud: Hud)
	local atual, maxima = Energia.de(jogador)
	local fracaoEnergia = if maxima > 0 then math.clamp(atual / maxima, 0, 1) else 0
	hud.preenchimento.Size = UDim2.fromScale(fracaoEnergia, 1)
	hud.valorEnergia.Text = `{atual} / {maxima}`

	local agora = Workspace:GetServerTimeNow()
	for _, quadro in hud.quadros do
		local falta = math.max(0, CombatController.prontaEm(quadro.id) - agora)
		local fracao = if quadro.recarga > 0 then math.clamp(falta / quadro.recarga, 0, 1) else 0
		quadro.sombra.Size = UDim2.fromScale(1, fracao)
		quadro.tempo.Text = if falta > 0 then string.format("%.1f", falta) else ""
		quadro.borda.Color = if atual < quadro.energia then COR_SEM_ENERGIA else COR_FUNDO
	end

	local texto, hora = CombatController.aviso()
	hud.aviso.Text = if texto and os.clock() - hora < TEMPO_AVISO then texto else ""
end

function CombatHudController:Start()
	local hud = criarHud()
	RunService.RenderStepped:Connect(function()
		atualizar(hud)
	end)
end

return CombatHudController
