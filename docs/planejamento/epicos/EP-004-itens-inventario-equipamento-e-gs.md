---
tipo: epico
id: EP-004
titulo: Itens, inventário, equipamento e GS
status: em-andamento
prioridade: must
marco: M1
criado: 2026-11-05
atualizado: 2026-11-23
---

# EP-004 · Itens, inventário, equipamento e GS

> Itens com `uid` gerado só no servidor, inventário, equipar arma, elmo, peitoral e botas, e o GS calculado pelo que se veste.

## Objetivo
Ser a base da progressão pelo equipamento e garantir que nenhum item exista em dois lugares.

## Contexto
Pilares 1 (busca por loot) e 5 (jogue como quiser). Abas [Armas e Armaduras](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#53e3dc55-5a40) e [Progressão](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#31c067be-9c32). Segue a regra 6 do `CLAUDE.md`: nenhum item pode existir em dois lugares.

## Escopo
**Dentro**
- Itens definidos como dados em `src/shared/` e instâncias com `uid` gerado só no servidor ([ADR-006](../../arquitetura/adr/ADR-006-itens-como-registros-com-uid-do-servidor.md), proposto).
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
Criadas pelo dev em 23/11, por delegação do Davi:

| História | Depende de |
| --- | --- |
| [US-016 · Catálogo de itens e contas de GS](../historias/US-016-catalogo-de-itens-e-gs.md) | — |
| [US-017 · Inventário no servidor com uid e kit inicial](../historias/US-017-inventario-no-servidor.md) | US-016 |
| [US-018 · Equipar e desequipar, com GS e atributos do personagem](../historias/US-018-equipar-gs-e-atributos.md) | US-017 |
| [US-019 · Tela de inventário e equipamento (PC)](../historias/US-019-tela-de-inventario.md) | US-018 |
| [US-020 · Sorteio de loot e baú de teste](../historias/US-020-sorteio-de-loot-e-bau-de-teste.md) | US-017 |
| [US-051 · Pegar os itens de baús e bolsas numa janela de saque](../historias/US-051-janela-de-saque.md) (pedido do Davi, 23/11) | US-020, US-026, US-043, US-050 |

O progresso está no [BACKLOG.md](../BACKLOG.md).

## Histórico
- 2026-11-05: épico criado com o M1, aprovado pelo Davi.
