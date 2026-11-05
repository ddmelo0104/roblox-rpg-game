---
tipo: epico
id: EP-004
titulo: Itens, inventário, equipamento e GS
status: backlog
prioridade: must
marco: M1
criado: 2026-11-05
atualizado: 2026-11-05
---

# EP-004 · Itens, inventário, equipamento e GS

> Itens com `uid` gerado só no servidor, inventário, equipar arma, elmo, peitoral e botas, e o GS calculado pelo que se veste.

## Objetivo
Ser a base da progressão pelo equipamento e garantir que nenhum item exista em dois lugares.

## Contexto
Pilares 1 (busca por loot) e 5 (jogue como quiser). Abas [Armas e Armaduras](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#53e3dc55-5a40) e [Progressão](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#31c067be-9c32). Segue a regra 6 do `CLAUDE.md`: nenhum item pode existir em dois lugares.

## Escopo
**Dentro**
- Itens definidos como dados em `src/shared/` e instâncias com `uid` gerado só no servidor (ADR-006, a escrever).
- Inventário, e equipar ou desequipar validados no servidor.
- Slots do M1: arma, elmo, peitoral e botas.
- A base inicial: espada longa, besta, arco e cajado de fogo, e armaduras leve, média e tanque, mescláveis peça por peça.
- GS pela fórmula da aba Progressão; tiers T1 a T4; 5 raridades.

**Fora**
- Escudos: só no M2 (decisão do Davi, 05/11).
- Aprimoramento, mercado e crafting.

## Critérios de conclusão
- [ ] Equipar e desequipar funcionam com 2 jogadores, e o servidor recusa item que não é do jogador
- [ ] Nenhum caminho cria ou duplica item fora do servidor
- [ ] O GS do personagem bate com a fórmula da aba Progressão

## Métricas de sucesso
Nenhum item duplicado nos testes de troca rápida e de sair do jogo no meio de uma ação.

## Dependências
- Depende de: EP-001 e ADR-006 (a escrever)
- Bloqueia: EP-003, EP-005 e EP-009

## Riscos
> [!WARNING]
> **Duplicação de itens**, a falha que mais mata RPGs com troca no Roblox. Probabilidade média, impacto altíssimo. Mitigação: `uid` só no servidor, *session locking* (EP-006) e testes de troca.

## Perguntas em aberto
- [ ] A tocha e o livro de magia entram no M1, ou a segunda mão inteira fica para o M2 junto com os escudos?

Os outros detalhes de itens estão nas abas [Armas e Armaduras](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#53e3dc55-5a40) e [Progressão](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#31c067be-9c32).

## Histórias
O progresso está no [BACKLOG.md](../BACKLOG.md).

## Histórico
- 2026-11-05: épico criado com o M1, aprovado pelo Davi.
