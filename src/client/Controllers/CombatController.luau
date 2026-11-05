--!strict
--[[
	CombatController.luau
	Habilidades no PC (US-012): cada tecla pede ao servidor uma habilidade da espada longa.
	Antes de pedir, o cliente confere o que já sabe (cooldown, energia, alvo travado e alcance)
	para avisar na hora. Depois desenha o efeito e começa a contar o cooldown sem esperar o
	servidor (previsão). Quem decide é o servidor (ADR-002, ADR-009): a resposta dele corrige o
	cooldown e, se ele recusar, o efeito previsto some e o motivo aparece no HUD.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Habilidades = require(Shared:WaitForChild("Habilidades") :: ModuleScript)
local Alvos = require(Shared:WaitForChild("Alvos") :: ModuleScript)
local Energia = require(Shared:WaitForChild("Energia") :: ModuleScript)
local Remotes = require(Shared:WaitForChild("Remotes") :: ModuleScript)
local ConfigCombate = require(Shared:WaitForChild("Config"):WaitForChild("Combate") :: ModuleScript)
local EspadaLonga = require(Shared:WaitForChild("Config"):WaitForChild("EspadaLonga") :: ModuleScript)
local CombatEffectsController = require(script.Parent.CombatEffectsController)
local TargetController = require(script.Parent.TargetController)

local CombatController = {}

local jogador = Players.LocalPlayer

-- Hora do servidor em que cada habilidade volta a ficar pronta (prevista aqui, corrigida pelo servidor).
local prontaEm: { [string]: number } = {}

-- O efeito desenhado na hora para cada habilidade, para apagar se o servidor recusar.
local efeitoPrevisto: { [string]: Instance } = {}

local ultimoAviso: string? = nil
local horaDoAviso = 0

local function avisar(texto: string)
	ultimoAviso = texto
	horaDoAviso = os.clock()
end

local function raizViva(): BasePart?
	local personagem = jogador.Character
	if not personagem then
		return nil
	end
	local humanoide = personagem:FindFirstChildOfClass("Humanoid")
	local raiz = personagem:FindFirstChild("HumanoidRootPart")
	if humanoide and humanoide.Health > 0 and raiz and raiz:IsA("BasePart") then
		return raiz
	end
	return nil
end

-- Confere o que dá para conferir no cliente. Devolve a direção da habilidade (no plano) e o alvo
-- que vai no pedido, ou nil e o aviso para o jogador.
local function prepararPedido(habilidade: any, raiz: BasePart): (Vector3?, Model?, string?)
	if Workspace:GetServerTimeNow() < (prontaEm[habilidade.id] or 0) then
		return nil, nil, `{habilidade.nome}: em recarga`
	end
	local energiaAtual = Energia.de(jogador)
	if energiaAtual < habilidade.energia then
		return nil, nil, "Sem energia"
	end

	local origem = raiz.Position
	local travado = TargetController.alvoAtual()
	local posicaoTravado = if travado then Alvos.posicao(travado) else nil

	if habilidade.forma == "Alvo" then
		if not travado or not posicaoTravado or not Alvos.ehAlvo(travado) or not Alvos.vivo(travado) then
			return nil, nil, `{habilidade.nome}: trave um inimigo primeiro`
		end
		if not Habilidades.noRaio(origem, posicaoTravado, habilidade.alcance, 0, ConfigCombate.ALTURA_ACERTO) then
			return nil, nil, `{habilidade.nome}: fora de alcance`
		end
		return Habilidades.direcaoNoPlano(posicaoTravado - origem), travado, nil
	end

	-- Com alvo travado, a habilidade sai na direção dele; sem trava, para onde o personagem olha.
	local direcao = if posicaoTravado then posicaoTravado - origem else raiz.CFrame.LookVector
	return Habilidades.direcaoNoPlano(direcao), nil, nil
end

local function usar(habilidade: any, evento: RemoteEvent)
	local raiz = raizViva()
	if not raiz then
		return
	end
	local direcao, alvo, motivo = prepararPedido(habilidade, raiz)
	if motivo then
		avisar(motivo)
		return
	end
	local frente = direcao or Habilidades.direcaoNoPlano(raiz.CFrame.LookVector) or Vector3.new(0, 0, -1)

	-- Previsão: cooldown e efeito na hora; o servidor confirma ou desfaz.
	prontaEm[habilidade.id] = Workspace:GetServerTimeNow() + habilidade.recarga
	local origem = CFrame.lookAt(raiz.Position, raiz.Position + frente)
	efeitoPrevisto[habilidade.id] = CombatEffectsController.desenhar(habilidade, origem, alvo)
	evento:FireServer(habilidade.id, frente, alvo)
end

-- A resposta do servidor: quando a habilidade fica pronta e, se ele recusou, o motivo.
local function aoResponder(id: string, pronta: number, motivo: string?)
	prontaEm[id] = pronta
	local efeito = efeitoPrevisto[id]
	efeitoPrevisto[id] = nil
	if not motivo then
		return
	end
	if efeito then
		efeito:Destroy()
	end
	local habilidade = Habilidades.porId(EspadaLonga, id)
	avisar(`{if habilidade then habilidade.nome else id}: {motivo}`)
end

-- Hora do servidor em que a habilidade volta a ficar pronta (0 se já está). Usado pelo HUD.
function CombatController.prontaEm(id: string): number
	return prontaEm[id] or 0
end

-- O último aviso para o jogador e quando ele apareceu (os.clock). Usado pelo HUD.
function CombatController.aviso(): (string?, number)
	return ultimoAviso, horaDoAviso
end

function CombatController:Start()
	local evento = Remotes.evento("RequestAbility")

	UserInputService.InputBegan:Connect(function(input, processado)
		if processado then
			return
		end
		for _, habilidade in EspadaLonga do
			if input.KeyCode == habilidade.tecla then
				usar(habilidade, evento)
				return
			end
		end
	end)

	evento.OnClientEvent:Connect(aoResponder)
end

return CombatController
