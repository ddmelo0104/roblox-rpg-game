--!strict
--[[
	TrainingDummyService.luau
	Bonecos de treino do protótipo (US-009, US-012). Se o place não tiver nenhum modelo com a tag
	de alvo, cria uma fileira de bonecos simples à frente do spawn, para testar a trava de alvo e
	as habilidades (Config/Treino diz quantos e o espaço entre eles).
	Quando a vida de um chega a zero, ele volta depois de Config/Treino.TEMPO_VOLTAR_BONECO.
	É um placeholder: modelos de verdade são feitos no Studio e só precisam da tag (Shared.Alvos.TAG).
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Alvos = require(ReplicatedStorage.Shared.Alvos)
local ConfigTreino = require(ReplicatedStorage.Shared.Config.Treino)

-- Cor das partes do boneco (só visual).
local COR_BONECO = Color3.fromRGB(196, 160, 110)

local TrainingDummyService = {}

-- O chão logo abaixo de um ponto, ou o próprio ponto se não houver nada embaixo.
local function chaoAbaixo(ponto: Vector3): Vector3
	local resultado = Workspace:Raycast(ponto + Vector3.new(0, 50, 0), Vector3.new(0, -200, 0))
	if resultado then
		return resultado.Position
	end
	return ponto
end

-- O centro da fileira, à frente do SpawnLocation (ou da origem, se o place não tiver spawn), e a
-- direção de lado a lado da fileira.
local function centroDaFileira(): (Vector3, Vector3)
	local localDeSpawn = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if localDeSpawn and localDeSpawn:IsA("BasePart") then
		local frente = localDeSpawn.CFrame.LookVector * ConfigTreino.DISTANCIA_DO_SPAWN
		return localDeSpawn.Position + frente, localDeSpawn.CFrame.RightVector
	end
	return Vector3.new(0, 0, -ConfigTreino.DISTANCIA_DO_SPAWN), Vector3.new(1, 0, 0)
end

local function novaParte(nome: string, tamanho: Vector3, centro: Vector3, modelo: Model): Part
	local parte = Instance.new("Part")
	parte.Name = nome
	parte.Size = tamanho
	parte.CFrame = CFrame.new(centro)
	parte.Anchored = true
	parte.Color = COR_BONECO
	parte.TopSurface = Enum.SurfaceType.Smooth
	parte.BottomSurface = Enum.SurfaceType.Smooth
	parte.Parent = modelo
	return parte
end

-- Monta o boneco com os pés em `chao` e o coloca no Workspace com a tag de alvo.
local function criarBoneco(chao: Vector3)
	local modelo = Instance.new("Model")
	modelo.Name = "Boneco de treino"

	novaParte("Perna esquerda", Vector3.new(1, 2, 1), chao + Vector3.new(-0.5, 1, 0), modelo)
	novaParte("Perna direita", Vector3.new(1, 2, 1), chao + Vector3.new(0.5, 1, 0), modelo)
	novaParte("Torso", Vector3.new(2, 2, 1), chao + Vector3.new(0, 3, 0), modelo)
	novaParte("Head", Vector3.new(2, 1, 1), chao + Vector3.new(0, 4.5, 0), modelo)
	local raiz = novaParte("HumanoidRootPart", Vector3.new(2, 2, 1), chao + Vector3.new(0, 3, 0), modelo)
	raiz.Transparency = 1
	raiz.CanCollide = false
	modelo.PrimaryPart = raiz

	local humanoide = Instance.new("Humanoid")
	humanoide.RequiresNeck = false
	humanoide.MaxHealth = ConfigTreino.VIDA_BONECO
	humanoide.Health = ConfigTreino.VIDA_BONECO
	humanoide.Parent = modelo

	CollectionService:AddTag(modelo, Alvos.TAG)
	modelo.Parent = Workspace

	local voltando = false
	humanoide.HealthChanged:Connect(function(vida)
		if vida > 0 or voltando then
			return
		end
		voltando = true
		task.delay(ConfigTreino.TEMPO_VOLTAR_BONECO, function()
			modelo:Destroy()
			criarBoneco(chao)
		end)
	end)
end

function TrainingDummyService:Start()
	if #CollectionService:GetTagged(Alvos.TAG) > 0 then
		return -- o place já tem alvos feitos no Studio
	end
	local centro, lado = centroDaFileira()
	local quantidade = ConfigTreino.QUANTIDADE_BONECOS
	for i = 1, quantidade do
		local deslocamento = (i - (quantidade + 1) / 2) * ConfigTreino.ESPACO_ENTRE_BONECOS
		criarBoneco(chaoAbaixo(centro + lado * deslocamento))
	end
end

return TrainingDummyService
