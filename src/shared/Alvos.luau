--!strict
--[[
	Alvos.luau
	O que conta como alvo de combate (US-009): um Model com Humanoid e a tag do CollectionService
	abaixo. Bonecos de treino têm a tag; os inimigos vão ganhar também (EP-008). Usado pela trava
	de alvo no cliente e, depois, pela validação das habilidades no servidor.
]]

local Alvos = {}

-- Tag do CollectionService para bonecos de treino e inimigos.
Alvos.TAG = "Alvo"

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

return table.freeze(Alvos)
