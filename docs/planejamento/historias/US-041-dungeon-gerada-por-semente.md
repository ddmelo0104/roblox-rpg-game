---
tipo: historia
id: US-041
titulo: Dungeon gerada por semente, numa instância do servidor
status: revisao
prioridade: must
epico: EP-010
pontos: 5
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-041 · Dungeon gerada por semente, numa instância do servidor

## História
**Como** jogador,
**quero** que cada dungeon seja montada na hora, de salas em sequência, sempre diferente,
**para que** explorar não fique repetido (Pilares 1 e 2).

## Contexto
Aba [Dungeons](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#1f67c338-4738):
- **Ordem das salas:** entrada, combates, uma sala sorteada, o mini-chefe, o combate elite e o chefe.
- **Semente:** a mesma semente gera a mesma dungeon.
- **Regras de morte:** a dungeon herda o tier e as regras da zona.

Instâncias no mesmo servidor, pelo [ADR-007](../../arquitetura/adr/ADR-007-instancias-de-dungeon-no-mesmo-servidor.md) (proposto). Decisões do dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)):
- **Números:** valem os do doc de design (3 a 5 salas de combate, 3 entradas e 60 ou 90 s), não os do vault.
- **Salas provisórias:** são feitas por código até as salas do Studio existirem.
- **Sala sorteada:** no M1 é sempre o tesouro; a armadilha e o evento vêm depois.

## Critérios de aceite
**Cenário 1: mesma semente**
- **Dado** uma semente
- **Quando** o gerador roda duas vezes
- **Então** sai a mesma lista de salas

**Cenário 2: instância**
- **Dado** um jogador entra por uma entrada
- **Quando** a instância é criada
- **Então** aparecem as salas em fila (entrada, 2 a 4 combates, tesouro, mini-chefe, elite e chefe) longe do mundo, com os inimigos de cada sala

**Cenário 3: regras da zona**
- **Dado** uma dungeon cuja entrada fica na zona Vermelha T3
- **Quando** o jogador está dentro
- **Então** o topo mostra "Dungeon · …", e valem o tier, a sorte, o PvP e o derrubado da Vermelha

**Cenário 4: instância vazia**
- **Dado** uma instância com a entrada fechada
- **Quando** ninguém fica dentro por 30 s
- **Então** ela é removida, com os inimigos

## Notas técnicas (arquiteto → dev)
- Lado: servidor
- Módulos afetados: `Shared.DungeonLayout` (gerador puro), `src/server/DungeonBuilder.luau` (salas provisórias, região de zona e pontos de spawn), `Services/DungeonService` (instâncias), `Config/Dungeons` (novo), `EnemyService` (inimigos sem renascer, que somem com a instância)
- Remotes e validação no servidor: nenhum nesta história
- Dados persistidos: nenhum

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):**
- **Gerador:** `DungeonLayout.generate(seed)` é uma função pura. O Output mostra a semente de cada instância (`[Dungeon] instance N (seed …)`), para reproduzir bugs.
- **Construtor:** monta salas de 60 × 60 studs com corredores de 24, uma região de zona com o tipo e o tier da entrada, e um ponto de retorno na primeira sala.
- **Inimigos:** os pontos de spawn de cada sala têm `Respawns = false`. Quando a instância some, os inimigos dela somem junto.

**Para o Davi testar no Studio:**
1. **Entrar:** dê Play e vá a uma das entradas de teste (um portal roxo, 80 studs atrás da fileira de inimigos, no meio da Azul, da Amarela e da Vermelha). Segure G: você aparece na primeira sala.
2. **Salas:** atravesse a dungeon. As salas estão em fila, com bandidos, o tesouro, o capitão (mini-chefe), o elite e o chefe.
3. **Topo da tela:** mostra a dungeon com a zona da entrada.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
