--!strict
--[[
	Alvos.luau
	O que conta como alvo de combate (US-009): um Model com Humanoid e a tag do CollectionService
	abaixo. Bonecos de treino têm a tag; os inimigos vão ganhar também (EP-008). Usado pela trava
	de alvo no cliente e pela conferência das habilidades no servidor (US-012).
]]

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Alvos = {}

-- Tag do CollectionService para bonecos de treino e inimigos.
Alvos.TAG = "Alvo"

-- Se a instância é um alvo de combate: um Model com a tag.
function Alvos.ehAlvo(instancia: Instance): boolean
	return instancia:IsA("Model") and CollectionService:HasTag(instancia, Alvos.TAG)
end

-- Todos os Models com a tag.
function Alvos.todos(): { Model }
	local lista: { Model } = {}
	for _, instancia in CollectionService:GetTagged(Alvos.TAG) do
		if instancia:IsA("Model") then
			table.insert(lista, instancia)
		end
	end
	return lista
end

-- Se o modelo tem um Humanoid com vida.
function Alvos.vivo(modelo: Model): boolean
	local humanoide = modelo:FindFirstChildOfClass("Humanoid")
	return humanoide ~= nil and humanoide.Health > 0
end

-- Posição do alvo: a PrimaryPart ou a HumanoidRootPart. nil se o modelo não tiver nenhuma.
function Alvos.posicao(modelo: Model): Vector3?
	local raiz = modelo.PrimaryPart or modelo:FindFirstChild("HumanoidRootPart")
	if raiz and raiz:IsA("BasePart") then
		return raiz.Position
	end
	return nil
end

-- Se nada bloqueia o caminho de `origem` até `destino`, tirando as instâncias de `ignorar`
-- (e tudo dentro delas).
function Alvos.temLinhaDeVisao(origem: Vector3, destino: Vector3, ignorar: { Instance }): boolean
	local parametros = RaycastParams.new()
	parametros.FilterType = Enum.RaycastFilterType.Exclude
	parametros.FilterDescendantsInstances = ignorar
	return Workspace:Raycast(origem, destino - origem, parametros) == nil
end

return table.freeze(Alvos)
