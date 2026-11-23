---
tipo: adr
id: ADR-006
titulo: Itens como registros com uid gerado só no servidor
status: proposto
epicos: EP-004
criado: 2026-11-23
decidido_em:
substitui:
substituido_por:
---

# ADR-006 · Itens como registros com uid gerado só no servidor

> [!NOTE]
> Status: **proposto** → aceito → (obsoleto | substituído).

## Contexto
O jogo tem saque total, mercado entre jogadores (M2) e itens que podem ser perdidos. A regra 6 do `CLAUDE.md` diz que nenhum item pode existir em dois lugares. A aba [Progressão](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#31c067be-9c32) propõe itens padronizados, como no Albion: uma Espada Longa T4 Rara é sempre igual a outra. O que muda de um item para outro é só o tier, a raridade, o aprimoramento e a durabilidade.

## Opções consideradas
### Opção A: itens como Instances do Roblox (Tools ou Models na mochila)
- Prós: é o caminho padrão do Roblox, e a mochila já existe.
- Contras:
  - O cliente vê e mexe nas Instances do personagem dele.
  - Salvar exige converter tudo para dados de qualquer jeito.
  - Duplicar e perder itens fica fácil com a replicação.

### Opção B: itens como registros de dados no servidor, cada um com um `uid`
Cada item é uma tabela `{ uid, itemId, tier, rarity, durability }`. O `uid` é gerado só pelo servidor (`HttpService:GenerateGUID`). O inventário, o equipamento e, depois, o banco e a bolsa de saque são listas de registros no servidor.
- Prós:
  - Toda mudança passa por uma função do servidor que tira o item de um lugar e põe no outro na mesma chamada, sem esperar nada no meio. Assim o item nunca fica em dois lugares.
  - O cliente recebe só uma cópia para mostrar.
  - O perfil salvo (EP-006) é a própria lista.
- Contras:
  - O visual (a espada na mão) é montado à parte, a partir do item equipado.
  - Mais código de inventário nosso.

### Opção C: itens empilhados sem `uid` (contagem por tipo)
- Prós: o mais simples e o menor no perfil.
- Contras: não rastreia o item individual. Durabilidade e, no M2, o aprimoramento e o histórico do mercado ficam impossíveis.

## Decisão
> [!IMPORTANT]
> **Proposta: opção B.**
> - O catálogo (o que cada item é) fica em `src/shared/Config/Items.luau`.
> - As contas puras (GS, sorteio de loot) ficam em `src/shared/`.
> - Os registros vivem só no `InventoryService`.

## Consequências
- **Positivas:** anti-duplicação por construção, perfil simples de salvar e mercado viável no M2.
- **Negativas e trade-offs aceitos:** o visual dos itens no personagem é feito à parte; o cliente depende das cópias enviadas pelo servidor.
- **O que passa a ser obrigatório:**
  - Só o servidor cria `uid`.
  - Mover um item é uma função única do servidor, sem `yield` entre tirar e pôr.
  - O cliente pede pelo `uid`, e o servidor confere a posse antes de agir.

## Referências
- Aba [Progressão](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#31c067be-9c32): itens padronizados, GS, raridades e tiers.
- [HttpService:GenerateGUID](https://create.roblox.com/docs/reference/engine/classes/HttpService#GenerateGUID)
