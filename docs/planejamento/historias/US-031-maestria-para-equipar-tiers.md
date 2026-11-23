---
tipo: historia
id: US-031
titulo: Maestria necessária para equipar tiers
status: revisao
prioridade: must
epico: EP-005
pontos: 2
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-031 · Maestria necessária para equipar tiers

## História
**Como** jogador,
**quero** precisar dominar a linha para usar tiers mais altos,
**para que** o poder venha de jogar, e não só de achar ou comprar o item.

## Contexto
Aba [Progressão](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#31c067be-9c32): dá para lootear e vender qualquer tier, mas para usar é preciso ter a maestria da linha: T1 0, T2 5, T3 15, T4 30 (e T5 45, T6 60, T7 80, T8 100). A pergunta "exigir maestria para equipar tiers altos?" tinha a proposta "sim", adotada pelo dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)).

## Critérios de aceite
**Cenário 1: sem maestria**
- **Dado** uma Espada longa T2 na mochila e Espadas com maestria 3
- **Quando** o jogador tenta equipar
- **Então** o servidor recusa e aparece "Inventário: requer Espadas 5"

**Cenário 2: com maestria**
- **Dado** Espadas com maestria 5
- **Quando** o jogador equipa a espada T2
- **Então** ela é equipada

**Cenário 3: aviso na mochila**
- **Dado** um item que o jogador ainda não pode usar
- **Quando** ele abre o inventário
- **Então** o nome do item aparece em vermelho, e os detalhes dizem "Requer Espadas 5 para usar"

## Notas técnicas (arquiteto → dev)
- Lado: servidor e cliente
- Módulos afetados: `InventoryService.addEquipRule` (regras de equipar), `MasteryService` (a regra da maestria), `Shared.Mastery.canWear`, `InventoryUiController`
- Remotes e validação no servidor: `RequestEquip`: o servidor confere a maestria da linha antes de equipar
- Dados persistidos: nenhum

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):** o `InventoryService` ganhou regras de equipar, que outros serviços registram sem criar dependência circular. O `MasteryService` registra a regra da maestria. O kit inicial é T1, que não pede maestria.

**Para o Davi testar no Studio:**
1. Abra o baú de teste (G) até sair um item T2 (cerca de 20% das vezes). Na mochila ele fica vermelho, e os detalhes mostram "Requer … 5 para usar".
2. Clique nele: aparece "Inventário: requer … 5".
3. Derrote uns 31 bandidos com a arma daquela linha (cerca de 5 minutos) até a maestria 5, ou use um item de outra linha que você já tenha. Agora ele equipa.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
