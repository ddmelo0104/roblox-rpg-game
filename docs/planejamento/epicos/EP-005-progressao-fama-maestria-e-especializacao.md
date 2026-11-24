---
tipo: epico
id: EP-005
titulo: Progressão por fama, maestria e especialização
status: em-andamento
prioridade: must
marco: M1
criado: 2026-11-05
atualizado: 2026-11-23
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
Criadas pelo dev em 23/11, por delegação do Davi.

| História | Depende de |
| --- | --- |
| [US-029 · Fama por abate, dividida pelo que o jogador veste](../historias/US-029-fama-por-abate.md) | US-026 |
| [US-030 · Especialização e maestria aumentam o GS](../historias/US-030-especializacao-e-maestria-no-gs.md) | US-029, US-018 |
| [US-031 · Maestria necessária para equipar tiers](../historias/US-031-maestria-para-equipar-tiers.md) | US-029 |
| [US-032 · Pop-up de fama e tela de maestria (PC)](../historias/US-032-pop-up-de-fama-e-tela-de-maestria.md) | US-029 |

**Ainda a escrever:** as habilidades alternativas liberadas pela especialização. Elas pedem o desenho de 2 ou 3 opções por slot de cada arma e uma tela para escolher, e entram depois da persistência (EP-006). A fama em grupo entra com o EP-012.

O progresso está no [BACKLOG.md](../BACKLOG.md).

## Histórico
- 2026-11-05: épico criado com o M1, aprovado pelo Davi.
