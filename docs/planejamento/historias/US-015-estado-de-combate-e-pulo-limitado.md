---
tipo: historia
id: US-015
titulo: Estado de combate e pulo limitado em combate
status: revisao
prioridade: must
epico: EP-001
pontos: 2
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-015 · Estado de combate e pulo limitado em combate

## História
**Como** jogador,
**quero** que o jogo saiba quando estou em combate e limite o pulo nesse momento,
**para que** a luta não vire pula-pula e as regras de zona tenham um estado de combate para usar.

## Contexto
Respostas do Davi em 23/11 às perguntas abertas da aba [Movimentação](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#df937961-4ee9):
- **Pulo em combate:** limitado.
- **Corrida:** o gasto de energia fica para depois.

O resto foi decidido pelo dev, por delegação do Davi, e está no [registro de decisões delegadas](../DECISOES-DELEGADAS.md):
- **"Em combate":** dura 15 s depois de causar ou levar dano. É o `TEMPO_COMBATE` da aba [Zonas e Risco](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#117aa7d2-031b).
- **Limite do pulo:** um intervalo de 1,5 s entre pulos.
- **Corrida em combate:** continua livre.

## Critérios de aceite
**Cenário 1: entrar e sair de combate**
- **Dado** um jogador fora de combate
- **Quando** ele acerta um boneco, ou leva um golpe do boneco que ataca
- **Então** "Em combate" aparece no HUD e some 15 s depois do último dano

**Cenário 2: pulo em combate**
- **Dado** o jogador em combate
- **Quando** ele aperta pular várias vezes seguidas
- **Então** só sai um pulo a cada 1,5 s

**Cenário 3: pulo fora de combate**
- **Dado** o jogador fora de combate
- **Quando** ele pula várias vezes seguidas
- **Então** pula como sempre

## Notas técnicas (arquiteto → dev)
- Lado: servidor (estado) e cliente (HUD e pulo)
- Módulos afetados: `src/server/Services/CombatStateService.luau`, `src/shared/CombatState.luau`, `src/server/Services/CombatService.luau`, `src/server/Services/DefenseService.luau`, `src/client/Controllers/MovementController.luau`, `src/client/Controllers/CombatHudController.luau`, `src/shared/Config/Combat.luau` (`COMBAT_TIME`) e `Movement.luau` (`JUMP_COOLDOWN_IN_COMBAT`)
- Remotes e validação no servidor: nenhum Remote novo; o estado é um atributo do Player definido só pelo servidor
- Dados persistidos: nenhum
- ADRs relevantes: [ADR-002](../../arquitetura/adr/ADR-002-servidor-autoritativo.md)

## Tarefas
- [x] Estado de combate no servidor (causar ou levar dano)
- [x] Intervalo de pulo em combate no cliente
- [x] "Em combate" no HUD
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):**
- **`CombatStateService`:** põe o jogador em combate por `COMBAT_TIME` (15 s) a cada dano que ele causa (habilidades) ou leva (golpe que passa pela defesa). O estado fica no atributo `InCombatUntil` do Player.
- **`MovementController`:** em combate, depois de cada pulo, o próximo só sai depois de `JUMP_COOLDOWN_IN_COMBAT` (1,5 s).
- **HUD:** "Em combate" aparece à esquerda da barra de energia.

**Limitação conhecida:** o intervalo do pulo é aplicado no cliente, que controla o personagem. Um exploiter poderia ignorá-lo. A conferência de altura no servidor vem com a validação de voo (US-011, limitações).

**Para o Davi testar no Studio:**
1. **Cenário 1:** acerte um boneco com Q. "Em combate" aparece à esquerda da barra de energia. Afaste-se e espere 15 s: o aviso some.
2. **Cenário 2:** acerte um boneco e aperte espaço várias vezes. O personagem pula uma vez a cada 1,5 s.
3. **Cenário 3:** espere sair de combate e pule várias vezes. Ele pula normalmente.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
