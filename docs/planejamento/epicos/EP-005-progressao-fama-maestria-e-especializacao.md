---
tipo: epico
id: EP-005
titulo: Progressão por fama, maestria e especialização
status: backlog
prioridade: must
marco: M1
criado: 2026-11-05
atualizado: 2026-11-05
---

# EP-005 · Progressão por fama, maestria e especialização

> Lutar dá fama ao que você usa: ela sobe a especialização do item e a maestria da linha, que liberam tiers e habilidades alternativas.

## Objetivo
Ficar mais forte sem nível de personagem, pelo que se veste e pelo que se domina.

## Contexto
Pilares 1, 2, 3 e 5. Regras na aba [Progressão](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#31c067be-9c32).

## Escopo
**Dentro**
- Fama por abate, com o multiplicador da zona.
- Especialização de 0 a 100 por item e maestria de 0 a 100 por linha.
- Requisito de maestria para equipar tiers mais altos (proposta da aba Progressão).
- Habilidades alternativas liberadas pela maestria.
- Pop-up de fama e tela da árvore de maestria (PC).

**Fora**
- Fama de PvP (M2), aprimoramento e nível de conta ou prestígio.

## Critérios de conclusão
- [ ] Um abate dá fama à arma e às peças usadas, com os pesos por slot da aba Progressão
- [ ] Subir de nível libera o que a árvore promete
- [ ] Os valores ficam em `src/shared/Config/`

## Métricas de sucesso
O ritmo medido no playtest fica perto da tabela de ritmo esperado da aba Progressão.

## Dependências
- Depende de: EP-004, e do EP-006 para guardar o progresso
- Bloqueia: —

## Riscos
> [!WARNING]
> **Farmar fama de longe com inimigo preso no terreno.** Probabilidade média, impacto médio. Mitigação: inimigo que não alcança o jogador reseta e não dá fama (EP-008).

## Perguntas em aberto
Itens padronizados, requisito de maestria e ritmo estão na aba [Progressão](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#31c067be-9c32).

## Histórias
O progresso está no [BACKLOG.md](../BACKLOG.md).

## Histórico
- 2026-11-05: épico criado com o M1, aprovado pelo Davi.
