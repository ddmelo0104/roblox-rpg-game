---
tipo: historia
id: US-048
titulo: Dungeon de grupo de teste
status: revisao
prioridade: must
epico: EP-012
pontos: 5
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-048 · Dungeon de grupo de teste

## História
**Como** grupo,
**quero** uma dungeon feita para grupos, com chefes mais fortes e baús maiores,
**para que** jogar junto renda tanto ou mais que jogar sozinho.

## Contexto
Aba [Dungeons](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#1f67c338-4738):
- **Davi, 05/11:** uma dungeon de grupo de teste entra no M1 e depois é clonada pelas áreas com variações de spawn.
- **Davi, 04/11:** as dungeons em grupo dão loot proporcional ao grupo, ou melhor.

Decisões do dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)):
- **Onde fica:** fixa, longe do mundo, com a entrada na zona Amarela de teste.
- **Salas:** 3 salas de elite, o mini-chefe e o chefe, todos elite.
- **Inimigos:** voltam em 240 s.
- **Baús:** 4 itens no mini-chefe e 8 no chefe, pensados para 4 jogadores e divididos entre quem está dentro.

## Critérios de aceite
**Cenário 1: entrar**
- **Dado** a entrada da dungeon de grupo (portal laranja)
- **Quando** o jogador segura G
- **Então** entra na primeira sala; um portal laranja ali mesmo leva de volta

**Cenário 2: chefes e baús**
- **Dado** o grupo dentro da dungeon
- **Quando** derrota o mini-chefe e depois o chefe
- **Então** aparecem baús de 4 e de 8 itens, divididos entre quem está dentro

**Cenário 3: voltar**
- **Dado** um chefe derrotado
- **Quando** passam 240 s
- **Então** ele volta, com o resto da sala

## Notas técnicas (arquiteto → dev)
- Lado: servidor
- Módulos afetados: `Services/GroupDungeonService` (novo), `DungeonBuilder` (opções: inimigos próprios e que voltam), `Config/Dungeons` (`GROUP_*`), `SplitChest`, `src/server/Teleport.luau` (o teleporte compartilhado com as dungeons solo)
- Remotes e validação no servidor: os prompts conferem que o jogador está dentro para abrir baús e sair
- Dados persistidos: nenhum

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):**
- **Montagem:** cada parte com a tag `GroupDungeonEntrance` ganha uma dungeon de grupo, montada uma vez com o construtor das dungeons solo. Isso já é o "modelo reaproveitável": outra entrada em outra área gera uma cópia, com a zona e o tier dela.
- **Variações de spawn:** ficam no `Config/Dungeons.GROUP_ROOM_ENEMIES`.

**Para o Davi testar no Studio:**
1. **Entrar:** a entrada fica na Amarela de teste, 160 studs atrás da fileira de inimigos (525 studs à esquerda). Segure G no portal laranja.
2. **Chefes:** derrote as salas de elite, o capitão e o chefe (é feito para um grupo). Cada um deixa um baú.
3. **Sair:** o portal laranja da primeira sala leva de volta.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
