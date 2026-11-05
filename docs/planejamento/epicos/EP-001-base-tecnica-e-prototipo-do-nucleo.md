---
tipo: epico
id: EP-001
titulo: Base técnica e protótipo do núcleo
status: em-andamento
prioridade: must
marco: M0
criado: 2026-10-29
atualizado: 2026-11-05
---

# EP-001 · Base técnica e protótipo do núcleo

> Fechar a fundação técnica e provar, no PC, que combate, movimento e câmera são bons de jogar e que o terreno realista roda bem, antes de começar os épicos do M1.

## Objetivo
O M1 foi aprovado em 04/11, mas várias regras de combate e de movimento só se decidem jogando, e o mapa realista só se decide medindo. Este épico entrega a base de código do gameplay e as respostas que faltam para construir o M1 com segurança.

## Contexto
Substitui o escopo antigo (Fundação do Projeto): proposto em 04/11 e aprovado pelo Davi em 05/11. Reforça o Pilar 2 (combate divertido) ao validar o combate antes de escalar o conteúdo.

## Escopo
**Dentro**
1. **Fechar a fundação:** US-001 a US-004 e US-006 estão em revisão (falta o teste do Davi no Studio); a US-005 é a próxima.
2. **Base de código do gameplay:** loader de Services e Controllers, Remotes com validação no servidor e `src/shared/Config/` tipado.
3. **ADRs:** ADR-001 a ADR-003 já aceitos (04/11); escrever o ADR-009 (acerto com tolerância de lag) e o ADR-010 (validação de movimento).
4. **Protótipo do núcleo, no PC:** personagem, câmera em shift-lock com trava de alvo, corrida e pulo, esquiva, parry e 3 habilidades com energia e cooldown, contra um boneco de treino. Regras nas abas [Combate e Habilidades](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f0d54cbd-810d), [Câmera e Mira](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f5514f82-709f) e [Movimentação](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#df937961-4ee9).
5. **Spike de desempenho do terreno:** um pedaço de terreno realista com vegetação e água, medido num PC modesto e num celular fraco ([Mundo e Terreno](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f460e959-73a7)).

**Fora**
- Itens, inventário e GS de verdade (EP-004), persistência (EP-006), inimigos com IA (EP-008), zonas e dungeons.
- UI final e controles de celular.

## Critérios de conclusão
- [ ] US-001 a US-006 concluídas pelo Davi
- [x] ADR-001 a ADR-003 aceitos (04/11, opção B nos três)
- [ ] ADR-009 e ADR-010 escritos
- [ ] No PC, o protótipo roda com 2 jogadores (Test → 2 players) e o servidor recusa intenções inválidas (cooldown, energia, alcance)
- [ ] Os valores de combate, movimento e câmera saem do protótipo para `src/shared/Config/`
- [ ] As perguntas de combate, câmera e movimento que dependem do protótipo estão respondidas
- [ ] O spike de terreno tem FPS, memória e um `RAIO_STREAMING` inicial medidos

## Métricas de sucesso
O Davi joga o protótipo e decide que o combate está bom o bastante para construir o M1 em cima dele.

## Dependências
- Depende de: [ADR-001](../../arquitetura/adr/ADR-001-desenvolvimento-externo-com-rojo-e-git.md), [ADR-002](../../arquitetura/adr/ADR-002-servidor-autoritativo.md) e [ADR-003](../../arquitetura/adr/ADR-003-luau-em-modo-strict.md)
- Bloqueia: os épicos do M1 (EP-002 a EP-012)

## Histórias
Criadas em 05/11, na ordem em que fazem sentido:

| História | Depende de |
| --- | --- |
| [US-007 · Loader de Services e Controllers](../historias/US-007-loader-de-services-e-controllers.md) | — |
| [US-008 · Config tipado do protótipo](../historias/US-008-config-tipado-do-prototipo.md) | — |
| [US-005 · Comunicação cliente-servidor de exemplo](../historias/US-005-comunicacao-cliente-servidor-de-exemplo.md) | US-007, US-008 |
| [US-010 · Corrida e pulo pedidos ao servidor](../historias/US-010-corrida-e-pulo.md) | US-005 |
| [US-009 · Câmera em shift-lock com trava de alvo e boneco de treino](../historias/US-009-camera-shift-lock-trava-de-alvo-e-boneco.md) | US-007, US-008 |
| [US-011 · Validação de movimento no servidor](../historias/US-011-validacao-de-movimento-no-servidor.md) | US-010 e ADR-010 |
| [US-012 · Três habilidades com energia e cooldown contra o boneco](../historias/US-012-tres-habilidades-com-energia-e-cooldown.md) | US-009 e ADR-009 |
| [US-013 · Esquiva e parry](../historias/US-013-esquiva-e-parry.md) | US-012 |
| [US-014 · Spike de desempenho do terreno](../historias/US-014-spike-de-desempenho-do-terreno.md) | — |

## Riscos
> [!WARNING]
> **O protótipo crescer demais.** Probabilidade média, impacto alto. Mitigação (proposta): 1 arma com 3 habilidades, 1 boneco de treino e o cenário mínimo.

> [!WARNING]
> **Curva de aprendizado do Rojo.** Probabilidade média, impacto baixo. Mitigação: seguir o README passo a passo e registrar o que travar.

## Perguntas em aberto
- [ ] O protótipo é descartável ou vira a base dos épicos de personagem e de combate? Proposta: vira a base, com código de verdade em `--!strict` e servidor autoritativo.
- [x] O vault do Obsidian fica dentro do repositório? Não: a documentação de design virou Claude Docs, e a de engenharia mora em `docs/`. (2026-11-04)
- [x] O repositório fica privado ou público? Público, como o Davi criou (2026-11-04). Por isso, os trechos copiados de guias de terceiros e as capturas de tela ficaram fora de `docs/referencias/`.

O progresso está no [BACKLOG.md](../BACKLOG.md).

## Histórico
- 2026-10-29: épico criado como Fundação do Projeto.
- 2026-11-04: projeto passado para o Claude Code, no repositório público `ddmelo0104/roblox-rpg-game`. US-001, US-002, US-003, US-004 e US-006 implementadas pelo dev e em revisão.
- 2026-11-05: escopo renovado para "Base técnica e protótipo do núcleo", aprovado pelo Davi. Histórias US-007 a US-014 criadas.
