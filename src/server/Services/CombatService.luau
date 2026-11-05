--!strict
--[[
	CombatService.luau
	Habilidades da espada longa do protótipo (US-012, aba Combate e Habilidades). O cliente só
	pede ("corte frontal nesta direção", "golpe neste alvo travado"). O servidor confere
	cooldown, alvo, alcance, linha de visão e energia, calcula quem foi atingido com as contas de
	Shared.Habilidades e a margem de lag (ADR-009), aplica o dano e avisa todos os clientes.
	Só modelos com a tag de alvo levam dano: o PvP depende das regras de zona, que ainda não existem.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Alvos = require(ReplicatedStorage.Shared.Alvos)
local ConfigCamera = require(ReplicatedStorage.Shared.Config.Camera)
local ConfigCombate = require(ReplicatedStorage.Shared.Config.Combate)
local EspadaLonga = require(ReplicatedStorage.Shared.Config.EspadaLonga)
local Habilidades = require(ReplicatedStorage.Shared.Habilidades)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Validar = require(ReplicatedStorage.Shared.Validar)
local Rede = require(script.Parent.Parent.Rede)
local EnergyService = require(script.Parent.EnergyService)

type Habilidade = Habilidades.Habilidade

local CombatService = {}

-- A arma do protótipo; para com uma mensagem clara se o Config tiver um campo errado.
local HABILIDADES = Habilidades.conferir(EspadaLonga, "Config/EspadaLonga")

-- Ids que o cliente pode pedir.
local IDS: { string } = {}
for _, habilidade in HABILIDADES do
	table.insert(IDS, habilidade.id)
end

-- Hora do servidor em que cada habilidade de cada jogador volta a ficar pronta.
local prontaEm: { [Player]: { [string]: number } } = {}

local pedido = Remotes.evento("RequestAbility")
local aviso = Remotes.evento("AbilityUsed")

local function validarPedido(id: any, direcao: any, alvo: any): (boolean, string?)
	local ok, motivo = Validar.umDe(id, IDS)
	if not ok then
		return false, motivo
	end
	ok, motivo = Validar.vetor(direcao, 0.5, 2)
	if not ok then
		return false, motivo
	end
	return Validar.instanciaOuNada(alvo)
end

local function prontasDe(jogador: Player): { [string]: number }
	local existentes = prontaEm[jogador]
	if existentes then
		return existentes
	end
	local novas: { [string]: number } = {}
	prontaEm[jogador] = novas
	return novas
end

-- Responde só para quem pediu: quando a habilidade fica pronta e, se recusou, o motivo.
local function responder(jogador: Player, id: string, motivo: string?)
	pedido:FireClient(jogador, id, prontasDe(jogador)[id] or 0, motivo)
end

local function partesDe(jogador: Player): (Humanoid?, BasePart?)
	local personagem = jogador.Character
	if not personagem then
		return nil, nil
	end
	local raiz = personagem:FindFirstChild("HumanoidRootPart")
	return personagem:FindFirstChildOfClass("Humanoid"), if raiz and raiz:IsA("BasePart") then raiz else nil
end

-- Personagens e alvos não bloqueiam golpe nem linha de visão: só o cenário bloqueia.
local function naoBloqueiam(): { Instance }
	local lista: { Instance } = {}
	for _, outro in Players:GetPlayers() do
		local personagem = outro.Character
		if personagem then
			table.insert(lista, personagem)
		end
	end
	for _, alvo in Alvos.todos() do
		table.insert(lista, alvo)
	end
	return lista
end

local function olhoDe(origem: Vector3): Vector3
	return origem + Vector3.new(0, ConfigCamera.ALTURA_FOCO, 0)
end

-- Os alvos vivos dentro da área (Frente ou EmVolta) e à vista de quem atacou.
local function alvosNaArea(habilidade: Habilidade, origem: Vector3, frente: Vector3): { Model }
	local ignorar = naoBloqueiam()
	local atingidos: { Model } = {}
	for _, alvo in Alvos.todos() do
		local posicao = Alvos.posicao(alvo)
		if not posicao or not Alvos.vivo(alvo) then
			continue
		end
		local margem, altura = ConfigCombate.MARGEM_LAG, ConfigCombate.ALTURA_ACERTO
		local dentro = if habilidade.forma == "Frente"
			then Habilidades.naFrente(origem, frente, posicao, habilidade.alcance, habilidade.largura, margem, altura)
			else Habilidades.noRaio(origem, posicao, habilidade.alcance, margem, altura)
		if dentro and Alvos.temLinhaDeVisao(olhoDe(origem), posicao, ignorar) then
			table.insert(atingidos, alvo)
		end
	end
	return atingidos
end

-- Confere o alvo travado do golpe no alvo. Devolve o alvo, ou nil e o motivo da recusa.
local function conferirAlvo(habilidade: Habilidade, origem: Vector3, pedidoAlvo: Instance?): (Model?, string?)
	if not pedidoAlvo or not Alvos.ehAlvo(pedidoAlvo) then
		return nil, "alvo inválido"
	end
	local alvo = pedidoAlvo :: Model
	local posicao = Alvos.posicao(alvo)
	if not posicao or not Alvos.vivo(alvo) then
		return nil, "alvo inválido"
	end
	local margem, altura = ConfigCombate.MARGEM_LAG, ConfigCombate.ALTURA_ACERTO
	if not Habilidades.noRaio(origem, posicao, habilidade.alcance, margem, altura) then
		return nil, "fora de alcance"
	end
	if not Alvos.temLinhaDeVisao(olhoDe(origem), posicao, naoBloqueiam()) then
		return nil, "sem linha de visão"
	end
	return alvo, nil
end

-- Tira a vida dos atingidos. Devolve se algum deles foi derrubado por este golpe.
local function aplicarDano(atingidos: { Model }, dano: number): boolean
	local derrubou = false
	for _, alvo in atingidos do
		local humanoide = alvo:FindFirstChildOfClass("Humanoid")
		if humanoide and humanoide.Health > 0 then
			humanoide:TakeDamage(dano)
			if humanoide.Health <= 0 then
				derrubou = true
			end
		end
	end
	return derrubou
end

local function usar(jogador: Player, id: string, direcao: Vector3, pedidoAlvo: Instance?)
	local habilidade = Habilidades.porId(HABILIDADES, id)
	local humanoide, raiz = partesDe(jogador)
	if not habilidade or not humanoide or not raiz or humanoide.Health <= 0 then
		responder(jogador, id, "sem personagem")
		return
	end

	local agora = Workspace:GetServerTimeNow()
	local prontas = prontasDe(jogador)
	if agora < (prontas[id] or 0) then
		responder(jogador, id, "em recarga")
		return
	end

	local origem = raiz.Position
	local frente = Habilidades.direcaoNoPlano(direcao)
		or Habilidades.direcaoNoPlano(raiz.CFrame.LookVector)
		or Vector3.new(0, 0, -1)

	local alvoTravado: Model? = nil
	if habilidade.forma == "Alvo" then
		local alvo, motivo = conferirAlvo(habilidade, origem, pedidoAlvo)
		if not alvo then
			responder(jogador, id, motivo)
			return
		end
		alvoTravado = alvo
		frente = Habilidades.direcaoNoPlano((Alvos.posicao(alvo) or origem) - origem) or frente
	end

	if not EnergyService.gastar(jogador, habilidade.energia) then
		responder(jogador, id, "sem energia")
		return
	end

	local atingidos = if alvoTravado then { alvoTravado } else alvosNaArea(habilidade, origem, frente)
	local derrubou = aplicarDano(atingidos, habilidade.dano)

	prontas[id] = if derrubou and habilidade.zeraAoDerrubar then agora else agora + habilidade.recarga
	responder(jogador, id, nil)
	aviso:FireAllClients(jogador, id, CFrame.lookAt(origem, origem + frente), atingidos, habilidade.dano)
end

function CombatService:Start()
	Rede.aoReceber("RequestAbility", validarPedido, usar)

	-- AbilityUsed é só aviso do servidor. Ouvir e ignorar evita a fila de eventos sem destino
	-- se um cliente disparar por ele.
	aviso.OnServerEvent:Connect(function() end)

	Players.PlayerRemoving:Connect(function(jogador)
		prontaEm[jogador] = nil
	end)
end

return CombatService
