---
tipo: historia
id: US-018
titulo: Equipar e desequipar, com GS e atributos do personagem
status: revisao
prioridade: must
epico: EP-004
pontos: 5
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-018 · Equipar e desequipar, com GS e atributos do personagem

## História
**Como** jogador,
**quero** trocar o que visto e ver meu GS mudar,
**para que** o equipamento decida minha vida, meu dano, meus cooldowns e minha resistência.

## Contexto
Abas [Progressão](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#31c067be-9c32) e [Armas e Armaduras](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#53e3dc55-5a40). O GS do personagem escala os atributos (dano e vida). O tipo de cada peça de armadura dá bônus diferentes: leve dá dano e cooldown, média dá dano e um pouco de vida, tanque dá vida, resistência e cooldown (Davi, 04/11). Os números são do dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)).

## Critérios de aceite
**Cenário 1: equipar**
- **Dado** um Peitoral de placa T2 na mochila
- **Quando** o jogador pede para equipar
- **Então** o servidor confere a posse, troca o peitoral, devolve o antigo para a mochila, e a vida máxima e o GS mudam

**Cenário 2: pedido inválido**
- **Dado** um uid que não é do jogador, ou um item no slot errado
- **Quando** o cliente pede para equipar
- **Então** o servidor recusa sem erro

**Cenário 3: dano e cooldown**
- **Dado** armadura leve completa
- **Quando** o jogador usa uma habilidade
- **Então** o dano sobe e o cooldown cai conforme os bônus do Config

## Notas técnicas (arquiteto → dev)
- Lado: servidor e cliente
- Módulos afetados: `InventoryService`, `src/server/Services/StatsService.luau`, `CombatService`, `DefenseService`, Remotes `RequestEquip` e `RequestUnequip`
- Remotes e validação no servidor: `RequestEquip(uid)` e `RequestUnequip(slot)`: tipo, posse do `uid`, slot do item e espaço na mochila
- Dados persistidos: nenhum por enquanto (EP-006)
- ADRs relevantes: [ADR-006](../../arquitetura/adr/ADR-006-itens-como-registros-com-uid-do-servidor.md), [ADR-002](../../arquitetura/adr/ADR-002-servidor-autoritativo.md)

## Tarefas
- [x] Equipar e desequipar validados no servidor
- [x] Atributos pelo GS e pelos bônus das peças, aplicados no personagem
- [x] Dano, cooldown e resistência usados no combate
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):**
- **Pedidos:**
  - `RequestEquip(uid)` e `RequestUnequip(slot)` são validados no servidor: tamanho do texto, slot da lista e posse do `uid` na mochila.
  - A troca acontece numa função só, sem esperar nada, e o item que saiu do slot volta para a mochila.
- **`StatsService`:**
  - Calcula os atributos pelo equipamento.
  - Vida máxima = 100 × multiplicador de vida, mantendo a fração de vida atual.
  - O GS vai para o atributo `GearScore`, e o HUD mostra "GS" na barra de energia.
- **Combate:**
  - O dano das habilidades é multiplicado pelo multiplicador de dano.
  - O cooldown é multiplicado pelo multiplicador de cooldown, também na previsão do cliente.
  - O dano recebido perde a fração da resistência.

**Limitação:** as habilidades ainda são as da espada longa, seja qual for a arma equipada. O EP-003 liga o kit à arma.

**Para o Davi testar no Studio:**
1. **Equipar:** abra o baú de teste até sair uma peça de placa, abra o inventário (I) e clique nela.
   - A peça vai para o slot, e a antiga volta para a mochila.
   - O GS e a vida máxima mudam: rode `print(game.Players.LocalPlayer.Character.Humanoid.MaxHealth)` na barra de comandos do cliente.
2. **Desequipar:** clique num slot equipado. O item volta para a mochila.
3. **Pedido inválido:** rode `game.ReplicatedStorage.Remotes.RequestEquip:FireServer("x")` no cliente. O servidor avisa `[Inventory] … not in the bag`, sem erro.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
