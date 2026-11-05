---
tipo: historia
id: US-010
titulo: Corrida e pulo pedidos ao servidor
status: revisao
prioridade: must
epico: EP-001
pontos: 2
sprint:
criado: 2026-11-05
atualizado: 2026-11-05
concluido_em:
---

# US-010 · Corrida e pulo pedidos ao servidor

## História
**Como** jogador,
**quero** correr segurando Shift e pular com a altura definida pelo jogo,
**para que** eu atravesse o mapa grande com mais agilidade.

## Contexto
Aba [Movimentação](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#df937961-4ee9): no M1, andar, correr e pular (decisão do Davi, 04/11). O cliente só pede para correr; quem decide a velocidade é o servidor ([ADR-002](../../arquitetura/adr/ADR-002-servidor-autoritativo.md)). Se a corrida gasta stamina é uma pergunta aberta da aba: nesta história ela é livre. A conferência de deslocamento contra speed hack é a US-011.

## Critérios de aceite
**Cenário 1: correr**
- **Dado** o jogador andando
- **Quando** ele segura Shift
- **Então** a velocidade vai para a de corrida, e ao soltar volta para a de andar

**Cenário 2: pedido validado**
- **Dado** um cliente que manda algo que não é booleano, ou pedidos demais por segundo
- **Quando** o pedido chega
- **Então** o servidor ignora e registra um aviso no Output, sem erro

**Cenário 3: pulo**
- **Dado** o jogador parado
- **Quando** ele pula
- **Então** a altura do pulo é a do Config

**Cenário 4: renascer**
- **Dado** um jogador correndo
- **Quando** ele morre e renasce
- **Então** volta andando, com os valores do Config

## Notas técnicas (arquiteto → dev)
- Lado: cliente (tecla e previsão) e servidor (decisão)
- Módulos afetados: `src/client/Controllers/MovementController.luau`, `src/server/Services/MovementService.luau`, `src/shared/Config/Movimento.luau`
- Remotes e validação no servidor: `RequestSprint` (RemoteEvent, um booleano), validado pela camada de rede da US-005
- Dados persistidos: nenhum
- ADRs relevantes: [ADR-002](../../arquitetura/adr/ADR-002-servidor-autoritativo.md)

## Tarefas
- [x] Tecla de correr no cliente, com a velocidade mudando na hora (previsão)
- [x] Servidor valida o pedido e define a velocidade
- [x] Altura do pulo e velocidade de andar aplicadas a cada personagem novo
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-05):** o Davi pediu em 05/11 para começar o código.
- **Cliente:** `MovementController` (cliente): segurar a tecla de correr (`Config/Movimento.TECLA_CORRER`, provisória: Shift) muda a velocidade na hora (previsão) e manda `RequestSprint(true)`; soltar manda `RequestSprint(false)`.
- **Servidor:** `MovementService` valida o pedido pela camada de rede da US-005 (só booleano, com limite por segundo) e define o `WalkSpeed` do personagem. O valor do servidor é o que vale. Todo personagem novo começa andando, com `JumpHeight` do Config.
- **Fora desta história:** a corrida é livre, sem stamina, porque isso ainda é pergunta aberta da aba Movimentação. A conferência do deslocamento contra speed hack é a US-011.

**Para o Davi testar no Studio:**
1. **Cenário 1:** dê Play, segure Shift andando e solte. A velocidade sobe e volta. Para ver o número, rode na barra de comandos (cliente) `print(game.Players.LocalPlayer.Character.Humanoid.WalkSpeed)` segurando e sem segurar: 24 e 16.
2. **Cenário 2:** em Test → Clients and Servers, na barra de comandos da janela do jogador, rode `game.ReplicatedStorage.Remotes.RequestSprint:FireServer("sim")`. O Output do servidor mostra `[Rede] RequestSprint recusado de …: esperava booleano, veio string`.
3. **Cenário 3:** pule. A altura é a padrão do Roblox. Troque `ALTURA_PULO` para 20 em `Config/Movimento`, salve, dê Play de novo e veja o pulo maior. Depois volte o valor.
4. **Cenário 4:** segure Shift e resete o personagem (Esc → Reset Character). Ele volta andando.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
