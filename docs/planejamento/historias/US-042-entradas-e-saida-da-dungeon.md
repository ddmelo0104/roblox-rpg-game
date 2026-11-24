---
tipo: historia
id: US-042
titulo: Entradas que aparecem e somem, e a saída da dungeon
status: revisao
prioridade: must
epico: EP-010
pontos: 3
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-042 · Entradas que aparecem e somem, e a saída da dungeon

## História
**Como** jogador,
**quero** achar entradas de dungeon pelo mundo, que somem um tempo depois que alguém entra, e poder sair antes do fim se precisar,
**para que** descobrir dungeons seja parte da exploração.

## Contexto
Aba [Dungeons](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#1f67c338-4738):
- **Entradas:** cada zona tem pontos de entrada possíveis, e só alguns ficam ativos. A entrada some um tempo depois que o último jogador entra (60 s na Azul e na Amarela, 90 s na Vermelha), e outra aparece em outro ponto.
- **Saída** (decisão do Davi): o portal só abre na conclusão; antes, dá para canalizar 30 s fora de combate.

Decisões do dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)):
- **Até 3 entradas abertas** por zona.
- **Sem entrar em combate:** não dá para entrar numa dungeon em combate.
- **Tecla X** começa e cancela a saída.

## Critérios de aceite
**Cenário 1: entrar**
- **Dado** uma entrada aberta (portal roxo)
- **Quando** o jogador, fora de combate, segura G
- **Então** entra na instância daquela entrada; quem entrar depois pela mesma entrada cai na mesma instância

**Cenário 2: em combate**
- **Dado** um jogador em combate
- **Quando** ele tenta entrar
- **Então** aparece "Dungeon: em combate"

**Cenário 3: a entrada some**
- **Dado** uma entrada usada
- **Quando** passam 60 s (90 s na Vermelha) da última entrada
- **Então** o portal some, e outro ponto da zona abre

**Cenário 4: saída pelo portal**
- **Dado** o chefe derrotado
- **Quando** o jogador segura G no portal que aparece
- **Então** volta para perto da entrada por onde veio

**Cenário 5: saída canalizada**
- **Dado** um jogador dentro, fora de combate
- **Quando** ele aperta X
- **Então** a tela conta 30 s e ele sai; tomar dano ou entrar em combate interrompe, e X de novo cancela

## Notas técnicas (arquiteto → dev)
- Lado: servidor e cliente
- Módulos afetados: `DungeonService` (entradas, entrar, portal de saída e canal), `ZoneService.forget` (os teleportes não contam como fugir pela fronteira), `DungeonController` (novo), `Config/Interface.DUNGEON_EXIT_KEY`
- Remotes e validação no servidor: `RequestDungeonExit(boolean)`: o servidor confere que o jogador está dentro e fora de combate. Os prompts conferem distância e combate
- Dados persistidos: nenhum

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):**
- **Pontos de entrada:** são partes com a tag `DungeonEntrance`, montadas no Studio. O traçado de teste ganha uma em cada zona, menos na cidade.
- **Teleportes:** pedem ao Roblox para carregar a área antes (`RequestStreamAroundAsync`) e passam pela validação de movimento.

**Para o Davi testar no Studio:**
1. **Entrar e a entrada sumir:** entre por uma entrada e anote o tempo. Sem ninguém entrar de novo, o portal some depois de 60 s.
2. **Saída canalizada:** dentro, aperte X: o texto conta 30 s e você volta para perto da entrada. Teste também tomar dano durante a contagem (interrompe).
3. **Portal:** derrote o chefe. Um portal roxo aparece; segure G para sair.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
