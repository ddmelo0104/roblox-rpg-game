---
tipo: historia
id: US-011
titulo: Validação de movimento no servidor
status: revisao
prioridade: must
epico: EP-001
pontos: 3
sprint:
criado: 2026-11-05
atualizado: 2026-11-23
concluido_em:
---

# US-011 · Validação de movimento no servidor

## História
**Como** arquiteto,
**quero** que o servidor confira se cada personagem se desloca mais rápido do que pode e puxe de volta quem passar,
**para que** speed hack e teleporte não funcionem.

## Contexto
No Roblox, o cliente controla a física do próprio personagem. A aba [Movimentação](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#df937961-4ee9) pede a correção com margem para não punir quem está com lag. Precisa do [ADR-010](../../arquitetura/adr/ADR-010-validacao-de-movimento-no-servidor.md) (proposto em 05/11, opção B) aceito antes de implementar.

## Critérios de aceite
**Cenário 1: speed hack corrigido**
- **Dado** um cliente que muda a própria velocidade para muito acima da permitida
- **Quando** ele anda
- **Então** o servidor puxa o personagem de volta para a última posição válida e registra um aviso

**Cenário 2: lag não é punido**
- **Dado** um jogador honesto com lag simulado no Studio
- **Quando** ele anda e corre
- **Então** não há correção

**Cenário 3: teleporte do servidor não conta**
- **Dado** um teleporte feito pelo próprio servidor (renascer, por exemplo)
- **Quando** o personagem muda de lugar
- **Então** não há correção

## Notas técnicas (arquiteto → dev)
- Lado: servidor
- Módulos afetados: `src/server/Services/MovementValidationService.luau`, `src/shared/Config/Movement.luau` (margem, folga e intervalo)
- Remotes e validação no servidor: nenhum Remote novo; usa a velocidade que o servidor decidiu na US-010
- Dados persistidos: nenhum
- ADRs relevantes: [ADR-010](../../arquitetura/adr/ADR-010-validacao-de-movimento-no-servidor.md) (proposto), [ADR-002](../../arquitetura/adr/ADR-002-servidor-autoritativo.md)

## Tarefas
- [x] Escrever o ADR-010 (proposto em 05/11)
- [ ] Aceite do Davi no ADR-010
- [x] Conferência periódica do deslocamento horizontal, com margem e correção
- [x] Exceção para teleportes do servidor
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):** o Davi pediu em 23/11 para seguir com tudo o que fosse possível. A história segue a opção B do [ADR-010](../../arquitetura/adr/ADR-010-validacao-de-movimento-no-servidor.md), que ainda está proposto.
- **`MovementValidationService`:** a cada 0,5 s, compara a distância horizontal que cada personagem andou desde a última posição válida com um orçamento de movimento.
  - O orçamento cresce com a velocidade que o servidor permite (`MovementService.allowedSpeed`), mais 25% de margem (`SPEED_MARGIN`, a `MARGEM_VELOCIDADE` da aba).
  - O que não é usado fica guardado, até 1,5 s de movimento (`MAX_LAG_BURST`). Assim, quem está com lag e entrega vários passos de uma vez não é puxado.
  - Por cima disso, há 4 studs de folga em cada conferência (`DISTANCE_TOLERANCE`).
  - Quem passa do orçamento volta para a última posição válida, e o Output do servidor mostra `[MovementValidation] pulled <nome> back: moved X studs, allowed Y`.
- **Exceções:**
  - Renascer reinicia a conferência.
  - `MovementValidationService.teleport` cobre os teleportes do servidor (portais, no futuro).
  - `allowExtraDistance` cobre os avanços aprovados pelo servidor (a esquiva da US-013).

**Limitações conhecidas:**
- **Só a distância horizontal:** voo e atravessar paredes ficam para depois, como a aba já prevê.
- **Trapaça pequena passa:** um speed hack de até 25% acima da velocidade, ou o que couber no orçamento guardado.
- **Sem punição:** ninguém é expulso; o servidor só puxa de volta e avisa no Output.

**Para o Davi testar no Studio** (Test → Clients and Servers, 1 jogador):
1. **Cenário 1 (speed hack):**
   - Na barra de comandos da janela do jogador, rode `game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 80` e ande. O personagem é puxado de volta várias vezes, e o Output do servidor mostra `[MovementValidation] pulled …`.
   - Depois rode `game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame += Vector3.new(100, 0, 0)`. O personagem volta para onde estava.
2. **Cenário 2 (lag não é punido):** em File → Studio Settings → Network, ponha `Incoming Replication Lag` em 0,3 e jogue normalmente: ande, corra e esquive (F). Não deve haver puxões nem avisos. Depois volte o valor para 0.
3. **Cenário 3 (renascer):** na barra do jogador, rode `game.Players.LocalPlayer.Character.Humanoid.Health = 0`. O personagem renasce no spawn, sem aviso.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
