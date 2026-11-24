---
tipo: historia
id: US-039
titulo: Reanimar, finalizar e desistir
status: revisao
prioridade: must
epico: EP-009
pontos: 5
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-039 · Reanimar, finalizar e desistir

## História
**Como** jogador,
**quero** poder reanimar quem caiu, finalizar um inimigo na zona Vermelha e desistir para não esperar,
**para que** a luta continue depois do derrubado e o risco da Vermelha seja real.

## Contexto
Aba [Zonas e Risco](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#117aa7d2-031b):
- **Reanimar:** um aliado reanima em 5 s.
- **Finalizar:** um jogador finaliza em 3 s, só na Vermelha e na Preta.
- **Interrupção:** os dois são interrompidos por dano.
- **Desistir:** renasce na hora, no ponto de retorno da zona. Se quem derrubou foi um jogador numa zona de saque total, desistir conta como ser finalizado.

Decisões do dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)):
- **Quem reanima:** qualquer jogador, porque o grupo só vem no EP-012.
- **Teclas:** reanimar fica no G e finalizar no H, para os dois aparecerem juntos.

## Critérios de aceite
**Cenário 1: reanimar**
- **Dado** um jogador derrubado
- **Quando** outro segura G ("Reanimar") por 5 s perto dele
- **Então** o derrubado levanta na hora, com 25% da vida

**Cenário 2: interrompido**
- **Dado** um jogador segurando "Reanimar"
- **Quando** ele toma dano durante a contagem
- **Então** não reanima, e aparece "interrompido por dano"

**Cenário 3: finalizar**
- **Dado** um jogador derrubado na Vermelha
- **Quando** outro, também na Vermelha, segura H ("Finalizar") por 3 s
- **Então** o derrubado é finalizado e perde o que carrega (US-040)

**Cenário 4: não finaliza fora da Vermelha**
- **Dado** um jogador derrubado na Azul ou na Amarela
- **Quando** alguém chega perto
- **Então** só aparece "Reanimar"

**Cenário 5: desistir**
- **Dado** um jogador derrubado por um monstro
- **Quando** ele clica em "Desistir"
- **Então** renasce na hora, no ponto de retorno da zona

**Cenário 6: desistir contra jogador**
- **Dado** um jogador derrubado por outro jogador na Vermelha
- **Quando** ele clica em "Desistir"
- **Então** a tela avisava que conta como ser finalizado, e ele perde o que carrega

## Notas técnicas (arquiteto → dev)
- Lado: servidor e cliente
- Módulos afetados: `KnockdownService` (prompts, desistir, pontos de retorno), `DefenseService.secondsSinceDamaged`, `ZoneService.returnPoint` (tag `ReturnPoint`), `Config/Interface` (`FINISH_KEY`), `KnockdownController`
- Remotes e validação no servidor: `RequestGiveUp` (sem argumentos): o servidor confere que o jogador está derrubado. Os prompts conferem distância, interrupção por dano e, no finalizar, a zona do finalizador
- Dados persistidos: nenhum

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):**
- **Prompts:** ficam no personagem derrubado, e o próprio derrubado não os vê.
- **Interrupção:** o servidor confere se quem segurou não tomou dano durante o tempo do prompt.
- **Pontos de retorno:** partes com a tag `ReturnPoint`. O traçado de teste tem um no meio de cada zona. Quem desiste volta ao da zona onde caiu.

**Ainda falta:** quem sai do jogo derrubado ou em combate escapa da regra. O personagem que fica 30 s no mundo (anti *combat logging*) vem numa história própria, com o perfil (EP-006).

**Para o Davi testar no Studio** (Test → Clients and Servers → 2 players):
1. **Reanimar:** o jogador 1 é derrubado pelos bandidos da Azul. O jogador 2 chega perto e segura G: o 1 levanta.
2. **Finalizar:** os dois vão para a Vermelha (esperem a proteção acabar). O 2 derruba o 1 e segura H por 3 s: o 1 é finalizado (US-040).
3. **Desistir:** derrubado por bandido, clique em "Desistir": você renasce no meio da zona.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
