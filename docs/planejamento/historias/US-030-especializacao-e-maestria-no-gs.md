---
tipo: historia
id: US-030
titulo: Especialização e maestria aumentam o GS
status: revisao
prioridade: must
epico: EP-005
pontos: 2
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-030 · Especialização e maestria aumentam o GS

## História
**Como** jogador,
**quero** que dominar meu equipamento aumente o GS dele,
**para que** o tempo de uso me deixe mais forte, além do loot.

## Contexto
Aba [Progressão](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#31c067be-9c32): o GS do item soma +2 por nível de especialização e +0,3 por nível de maestria da linha; os atributos escalam com o GS.

## Critérios de aceite
**Cenário 1: GS sobe**
- **Dado** a Espada longa com especialização 5 e Espadas com maestria 5
- **Quando** o servidor calcula o GS
- **Então** o GS da espada é 100 + 2 × 5 + 0,3 × 5 = 111,5, e o GS do personagem e os atributos sobem junto

**Cenário 2: subir de nível**
- **Dado** um jogador que sobe um nível
- **Quando** o nível muda
- **Então** a vida máxima e o dano são recalculados na hora, e o GS do HUD muda

## Notas técnicas (arquiteto → dev)
- Lado: servidor e cliente
- Módulos afetados: `Shared.Items` (`characterGearScore` e `characterStats` recebem os níveis), `Shared.Mastery.levelsOf`, `Services/StatsService` (recalcula quando um nível sobe), `InventoryController` (a mesma conta no cliente)
- Remotes e validação no servidor: nenhum
- Dados persistidos: nenhum

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):** o `StatsService` passa os níveis do jogador para o `Shared.Items` e recalcula quando um nível sobe (`MasteryService.onChanged`). O cliente faz a mesma conta com a cópia do progresso, e a tela do inventário mostra o GS do item já com os níveis.

**Para o Davi testar no Studio:**
1. Anote o GS no HUD e derrote alguns bandidos. A cada nível da arma ou da linha, o GS sobe um pouco.
2. No inventário (I), passe o mouse sobre a espada: aparecem a especialização e a maestria, e o GS do item com elas.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
