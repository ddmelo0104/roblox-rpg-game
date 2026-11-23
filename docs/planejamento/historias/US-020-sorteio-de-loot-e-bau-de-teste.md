---
tipo: historia
id: US-020
titulo: Sorteio de loot e baú de teste
status: revisao
prioridade: must
epico: EP-004
pontos: 3
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-020 · Sorteio de loot e baú de teste

## História
**Como** jogador,
**quero** abrir um baú e ganhar um item sorteado pelas regras de loot,
**para que** dê para testar inventário e equipamento agora, e os inimigos e dungeons usem o mesmo sorteio depois.

## Contexto
Aba [Progressão](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#31c067be-9c32):
- A raridade sai das chances base, deslocadas pela sorte da zona.
- O tier sai 75% no tier da zona, 20% um abaixo e 5% um acima.

O baú de teste é uma ferramenta do protótipo, como os bonecos. O sorteio vale para os drops do EP-008 e os baús do EP-010.

## Critérios de aceite
**Cenário 1: abrir o baú**
- **Dado** o baú de teste ao lado do spawn
- **Quando** o jogador segura G nele
- **Então** um item sorteado entra na mochila e o nome dele aparece

**Cenário 2: sorteio**
- **Dado** 10.000 sorteios com sorte 1,0
- **Quando** as raridades são contadas
- **Então** elas ficam perto de 70%, 22%, 6%, 1,8% e 0,2%

**Cenário 3: longe do baú**
- **Dado** um pedido de abrir o baú vindo de longe
- **Quando** ele chega ao servidor
- **Então** o servidor recusa

## Notas técnicas (arquiteto → dev)
- Lado: servidor (e compartilhado para o sorteio)
- Módulos afetados: `src/shared/Loot.luau`, `src/shared/Config/Loot.luau`, `src/server/Services/ChestService.luau`
- Remotes e validação no servidor: ProximityPrompt; o servidor confere a distância
- Dados persistidos: nenhum
- ADRs relevantes: [ADR-006](../../arquitetura/adr/ADR-006-itens-como-registros-com-uid-do-servidor.md)

## Tarefas
- [x] Sorteio de raridade, tier e item em funções puras
- [x] Baú com ProximityPrompt e distância conferida no servidor
- [x] Baú de teste perto do spawn
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):**
- **`Shared.Loot`:**
  - A raridade sai dos pesos × sorte^(r − 1). Os números batem com a tabela da aba: com sorte 1,25, por exemplo, dá 63,1%, 24,8%, 8,5%, 3,2% e 0,44%.
  - O tier sai 75% no tier da zona, 20% um abaixo e 5% um acima, dentro de T1 a T4.
  - O item é sorteado no catálogo, todos com a mesma chance. O `Random` vem de fora, para repetir com semente.
- **`ChestService`:**
  - Toda parte com a tag `LootChest` vira um baú: ProximityPrompt "Abrir", segurando G por 0,3 s (o E padrão do Roblox é tecla de habilidade; mudado em 23/11 com a US-026).
  - O servidor confere a distância (12 studs) e espera 1 s entre aberturas.
  - O item sorteado vai para a mochila, e o aviso "Baú: <item>" aparece.
  - Se o place não tiver baús, aparece um baú de teste à esquerda do spawn.

**Para o Davi testar no Studio:**
1. **Abrir:** chegue perto do baú marrom à esquerda do spawn e segure G. Um item entra na mochila, e o nome dele aparece no HUD.
2. **Sorteio:** abra o baú várias vezes. Quase tudo sai Comum e Incomum, com Raros às vezes. Como no Albion, Épico e Lendário são raros.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
