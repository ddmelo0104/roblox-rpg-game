---
tipo: historia
id: US-043
titulo: Mini-chefe, chefe e baús divididos
status: revisao
prioridade: must
epico: EP-010
pontos: 5
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-043 · Mini-chefe, chefe e baús divididos

## História
**Como** jogador,
**quero** que a dungeon termine com um mini-chefe e um chefe que deixam baús,
**para que** valha o risco (Pilar 1, a busca por loot).

## Contexto
Aba [Dungeons](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#1f67c338-4738):
- **Baús:** o mini-chefe deixa um baú e o chefe um baú grande, com as chances de baú de chefe da aba Progressão.
- **Fama:** o mini-chefe vale ×10 e o chefe ×30.
- **Divisão** (decisão do Davi): a dungeon solo aceita mais jogadores, mas o loot é dividido e pensado para 2.
- **Inimigos de dungeon** não renascem.

Decisões do dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)):
- **Chefes:** Capitão e Chefe dos bandidos.
- **Baús:** o do mini-chefe tem 2 itens, o do chefe 4 e o do tesouro 1, divididos entre quem está dentro. O que não cabe na mochila vai para uma bolsa do jogador.

## Critérios de aceite
**Cenário 1: mini-chefe**
- **Dado** o Capitão dos bandidos
- **Quando** ele é derrotado
- **Então** aparece um baú com 2 itens, e quem o derrotou ganha 10× a fama de um bandido

**Cenário 2: chefe**
- **Dado** o Chefe dos bandidos
- **Quando** ele é derrotado
- **Então** aparecem um baú com 4 itens e o portal de saída, e a fama é 30× a de um bandido

**Cenário 3: baú dividido**
- **Dado** dois jogadores dentro da dungeon
- **Quando** um deles abre o baú do chefe
- **Então** os 4 itens são divididos, 2 para cada, na mochila de cada um

**Cenário 4: sem resetar**
- **Dado** um baú aberto
- **Quando** alguém sai e entra de novo
- **Então** o baú não volta: ele pertence à instância

**Cenário 5: mochila cheia**
- **Dado** um jogador com a mochila cheia
- **Quando** ele recebe itens de um baú
- **Então** os itens dele ficam numa bolsa no chão, só para ele nos primeiros 20 s

## Notas técnicas (arquiteto → dev)
- Lado: servidor
- Módulos afetados: `Config/Enemies` (`BanditCaptain` e `BanditChief`, com `rank` e `scale`), `Config/Progression` (multiplicadores de fama), `Shared.Enemies.rankFameMultiplier`, `EnemyService.onKilled`, `DungeonService` (baús e portal)
- Remotes e validação no servidor: o prompt do baú confere que o jogador está dentro da instância e perto do baú; só a primeira abertura conta
- Dados persistidos: os itens recebidos, pelo inventário do perfil

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):**
- **Chefes:** o `EnemyService` avisa cada abate (`onKilled`). O `DungeonService` olha o atributo `DungeonRole` do ponto de spawn para pôr o baú e, no chefe, o portal.
- **Baús:** os itens são sorteados com o tier e a sorte da zona da entrada e com as chances de baú de chefe, e divididos em rodízio a partir de um jogador sorteado.
- **Tamanho:** o capitão é 1,5× maior e o chefe 2× maior.

**Para o Davi testar no Studio:**
1. **Mini-chefe:** derrote o Capitão (a sala depois do tesouro). Aparece um baú; segure G: 2 itens na mochila.
2. **Chefe:** derrote o Chefe (a última sala). O baú dá 4 itens, e o portal de saída abre.
3. **Dividido** (2 jogadores): entrem pela mesma entrada e abram o baú do chefe. Cada um recebe 2 itens.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
