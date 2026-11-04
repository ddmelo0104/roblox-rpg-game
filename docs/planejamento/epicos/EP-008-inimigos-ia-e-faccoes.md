---
tipo: epico
id: EP-008
titulo: Inimigos, IA e facções
status: backlog
prioridade: must
marco: M1
criado: 2026-11-05
atualizado: 2026-11-05
---

# EP-008 · Inimigos, IA e facções

> Inimigos de Stardawn por zona e tier, com IA simples, que dormem sem jogador por perto, e as facções das dungeons.

## Objetivo
Dar o que combater em cada zona, com a dificuldade vinda do lugar, e não do nível.

## Contexto
Pilares 2 e 4. Abas [Dungeons](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#1f67c338-4738), [Zonas e Risco](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#117aa7d2-031b) e [Progressão](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#31c067be-9c32).

## Escopo
**Dentro**
- Inimigos por zona e tier de Stardawn, com os dados em Config.
- IA: perceber, perseguir, atacar e voltar; o inimigo que não alcança o jogador reseta e não dá fama.
- Inimigos dormem quando não há jogador por perto.
- Drops pela chance por abate da aba Progressão.
- Facção por região para as dungeons, com inimigos de efeito ao morrer.

**Fora**
- Chefes de mundo e raides (M3).

## Critérios de conclusão
- [ ] Cada zona do M1 tem inimigos do tier dela
- [ ] Inimigo preso no terreno reseta e não dá fama
- [ ] Com a zona cheia de inimigos dormindo, o servidor fica dentro do orçamento

## Métricas de sucesso
Num playtest, as lutas não parecem repetidas (Pilar 2).

## Dependências
- Depende de: EP-003 e EP-007
- Bloqueia: EP-010 e EP-012

## Riscos
> [!WARNING]
> **IA cara no servidor.** Probabilidade média, impacto alto. Mitigação: dormir longe de jogadores e poucas checagens por segundo.

## Perguntas em aberto
As facções e os temas das zonas de Stardawn estão na aba [Dungeons](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#1f67c338-4738).

## Histórias
O progresso está no [BACKLOG.md](../BACKLOG.md).

## Histórico
- 2026-11-05: épico criado com o M1, aprovado pelo Davi.
