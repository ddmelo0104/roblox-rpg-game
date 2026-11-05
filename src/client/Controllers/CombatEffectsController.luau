--!strict
--[[
	CombatEffectsController.luau
	Efeitos das habilidades (US-012), só visuais: o desenho da área (ou do golpe até o alvo) e o
	número de dano em cima de quem foi atingido. Quem usa a habilidade desenha na hora, pelo
	CombatController; os outros jogadores desenham quando o servidor avisa (AbilityUsed).
	O número de dano é sempre o que o servidor aplicou.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Habilidades = require(Shared:WaitForChild("Habilidades") :: ModuleScript)
local Alvos = require(Shared:WaitForChild("Alvos") :: ModuleScript)
local Remotes = require(Shared:WaitForChild("Remotes") :: ModuleScript)
local EspadaLonga = require(Shared:WaitForChild("Config"):WaitForChild("EspadaLonga") :: ModuleScript)

-- Só visual: quanto tempo cada efeito fica na tela e as cores de cada forma de habilidade.
local TEMPO_AREA = 0.35
local TEMPO_NUMERO = 0.8
local SUBIDA_NUMERO = 2
local CORES: { [string]: Color3 } = {
	Frente = Color3.fromRGB(255, 220, 120),
	Alvo = Color3.fromRGB(255, 120, 90),
	EmVolta = Color3.fromRGB(140, 200, 255),
}

local CombatEffectsController = {}

local jogador = Players.LocalPlayer
local pasta: Folder? = nil

-- Pasta local (só deste cliente) para os efeitos.
local function pastaDeEfeitos(): Folder
	local atual = pasta
	if atual and atual.Parent then
		return atual
	end
	local nova = Instance.new("Folder")
	nova.Name = "EfeitosDeCombate"
	nova.Parent = Workspace
	pasta = nova
	return nova
end

-- Uma parte só de enfeite: não colide, não é tocada e não bloqueia raios (nem a trava de alvo).
local function novaParte(cor: Color3): Part
	local parte = Instance.new("Part")
	parte.Anchored = true
	parte.CanCollide = false
	parte.CanQuery = false
	parte.CanTouch = false
	parte.CastShadow = false
	parte.Material = Enum.Material.Neon
	parte.Color = cor
	parte.Transparency = 0.5
	return parte
end

-- Some aos poucos e se apaga.
local function sumir(parte: BasePart)
	TweenService:Create(parte, TweenInfo.new(TEMPO_AREA), { Transparency = 1 }):Play()
	task.delay(TEMPO_AREA, function()
		parte:Destroy()
	end)
end

-- Desenha a habilidade a partir de `origem` (posição e direção de quem usou), na altura da
-- cintura. Devolve a parte do desenho, para quem previu poder apagar se o servidor recusar.
function CombatEffectsController.desenhar(habilidade: any, origem: CFrame, alvo: Model?): BasePart?
	local parte = novaParte(CORES[habilidade.forma] or Color3.new(1, 1, 1))
	if habilidade.forma == "Frente" then
		parte.Size = Vector3.new(habilidade.largura, 0.2, habilidade.alcance)
		parte.CFrame = origem * CFrame.new(0, 0, -habilidade.alcance / 2)
	elseif habilidade.forma == "EmVolta" then
		-- O eixo do cilindro é o X; girado 90° em Z, ele fica de pé e vira um disco no chão.
		parte.Shape = Enum.PartType.Cylinder
		parte.Size = Vector3.new(0.2, habilidade.alcance * 2, habilidade.alcance * 2)
		parte.CFrame = CFrame.new(origem.Position) * CFrame.Angles(0, 0, math.rad(90))
	else
		local posicao = if alvo then Alvos.posicao(alvo) else nil
		local distancia = if posicao then (posicao - origem.Position).Magnitude else 0
		if not posicao or distancia < 0.5 then
			parte:Destroy()
			return nil
		end
		parte.Size = Vector3.new(0.4, 0.4, distancia)
		parte.CFrame = CFrame.lookAt(origem.Position, posicao) * CFrame.new(0, 0, -distancia / 2)
	end
	parte.Parent = pastaDeEfeitos()
	sumir(parte)
	return parte
end

-- Mostra o dano subindo e sumindo em cima do alvo.
function CombatEffectsController.mostrarDano(alvo: Model, dano: number)
	local raiz = alvo.PrimaryPart or alvo:FindFirstChild("HumanoidRootPart")
	if not raiz or not raiz:IsA("BasePart") then
		return
	end

	local quadro = Instance.new("BillboardGui")
	quadro.Size = UDim2.fromOffset(80, 30)
	quadro.StudsOffset = Vector3.new(0, 3, 0)
	quadro.AlwaysOnTop = true
	quadro.Adornee = raiz

	local texto = Instance.new("TextLabel")
	texto.Size = UDim2.fromScale(1, 1)
	texto.BackgroundTransparency = 1
	texto.TextSize = 24
	texto.TextColor3 = Color3.fromRGB(255, 230, 120)
	texto.TextStrokeTransparency = 0.3
	texto.Text = tostring(math.floor(dano + 0.5))
	texto.Parent = quadro
	quadro.Parent = pastaDeEfeitos()

	local info = TweenInfo.new(TEMPO_NUMERO)
	TweenService:Create(quadro, info, { StudsOffset = quadro.StudsOffset + Vector3.new(0, SUBIDA_NUMERO, 0) }):Play()
	TweenService:Create(texto, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(TEMPO_NUMERO, function()
		quadro:Destroy()
	end)
end

-- O aviso do servidor: alguém usou uma habilidade, de `origem`, e atingiu `atingidos`.
local function aoUsarem(autor: Player, id: string, origem: CFrame, atingidos: { Model }, dano: number)
	local habilidade = Habilidades.porId(EspadaLonga, id)
	if not habilidade then
		return
	end
	-- Quem usou já desenhou na hora (previsão); os outros desenham agora.
	if autor ~= jogador then
		CombatEffectsController.desenhar(habilidade, origem, atingidos[1])
	end
	for _, alvo in atingidos do
		CombatEffectsController.mostrarDano(alvo, dano)
	end
end

function CombatEffectsController:Start()
	Remotes.evento("AbilityUsed").OnClientEvent:Connect(aoUsarem)
end

return CombatEffectsController
