---
tipo: epico
id: EP-011
titulo: HUD, UI e onboarding
status: backlog
prioridade: must
marco: M1
criado: 2026-11-05
atualizado: 2026-11-05
---

# EP-011 · HUD, UI e onboarding

> HUD de combate e de GS, telas de inventário e de maestria, mapa do mundo e uma quest de tutorial simples na zona Azul.

## Objetivo
O jogador entende o que tem, o que pode fazer e onde está o risco, e aprende o básico no tutorial.

## Contexto
Pilares 2 e 4. Abas [Combate e Habilidades](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f0d54cbd-810d), [Progressão](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#31c067be-9c32) e [Zonas e Risco](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#117aa7d2-031b).

## Escopo
**Dentro**
- HUD: vida, energia, cooldowns e GS.
- Telas de inventário e equipamento, e da árvore de maestria.
- Aviso de zona de risco, borda vermelha e mapa do mundo.
- Uma quest de tutorial simples na zona Azul de Stardawn, só para o M1 (decisão do Davi, 05/11).

**Fora**
- UI de celular e um sistema de quests completo.

## Critérios de conclusão
- [ ] Toda informação de combate aparece no HUD, vinda do servidor
- [ ] Um jogador novo termina a quest de tutorial sem ajuda

## Métricas de sucesso
No playtest, ninguém precisa perguntar o que fazer depois de nascer.

## Dependências
- Depende de: EP-003, EP-004 e EP-007
- Bloqueia: —

## Riscos
> [!WARNING]
> **A UI mostrar um estado diferente do servidor.** Probabilidade média, impacto médio. Mitigação: a UI só lê o estado replicado.

## Perguntas em aberto
O conteúdo da quest de tutorial está na aba [Zonas e Risco](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#117aa7d2-031b).

## Histórias
O progresso está no [BACKLOG.md](../BACKLOG.md).

## Histórico
- 2026-11-05: épico criado com o M1, aprovado pelo Davi.
