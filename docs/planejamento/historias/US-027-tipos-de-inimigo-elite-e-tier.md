---
tipo: historia
id: US-027
titulo: Tipos de inimigo, elite, escala por tier e pontos de spawn
status: revisao
prioridade: must
epico: EP-008
pontos: 3
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-027 · Tipos de inimigo, elite, escala por tier e pontos de spawn

## História
**Como** jogador,
**quero** inimigos diferentes (corpo a corpo, à distância, elite), mais fortes nas zonas de tier maior,
**para que** as lutas não se repitam (Pilar 2) e a dificuldade venha do lugar (Pilar 4).

## Contexto
Aba [Zonas e Risco](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#117aa7d2-031b): o tier da zona define a força dos inimigos e o loot, e o GS recomendado é 100 × tier + 50. Aba [Progressão](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#31c067be-9c32): elite dá ×3 de fama. Decisões do dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)):
- **Força pelo tier:** a vida e o dano usam o multiplicador de atributos do GS recomendado da zona: T1 ×1,04, T2 ×1,12, T3 ×1,20 e T4 ×1,28. Um inimigo do tier T é tão forte quanto um jogador com o GS recomendado.
- **Elite:** ×3 de vida, ×1,5 de dano e corpo 25% maior.
- **Facção de teste, Bandidos:** o bandido (corpo a corpo), o bandido arqueiro (à distância) e o bandido com pólvora (US-028). As facções das zonas ficam para o EP-007 e o EP-010.
- **Renascer:** o inimigo do mundo aberto volta ao ponto de spawn em 45 s.

## Critérios de aceite
**Cenário 1: arqueiro**
- **Dado** um bandido arqueiro que viu o jogador
- **Quando** ele atira
- **Então** ele para a uns 28 studs, mostra o aviso e dispara um risco de luz; só a esquiva evita (o parry só pega golpe corpo a corpo)

**Cenário 2: elite**
- **Dado** o bandido de elite
- **Quando** o jogador luta com ele
- **Então** ele é maior, tem o triplo da vida e bate 50% mais forte

**Cenário 3: tier**
- **Dado** um ponto de spawn com `Tier = 3`
- **Quando** o inimigo nasce
- **Então** a vida e o dano dele são os do tier 3 (×1,20 em vez de ×1,04)

**Cenário 4: renascer**
- **Dado** um inimigo derrotado
- **Quando** passam 45 s
- **Então** outro nasce no mesmo ponto de spawn

**Cenário 5: área de teste**
- **Dado** um place sem pontos de spawn
- **Quando** o servidor inicia
- **Então** aparece uma fila à esquerda do spawn: 2 bandidos, 1 arqueiro, 1 bandido com pólvora e 1 bandido de elite, 50 studs entre os grupos

## Notas técnicas (arquiteto → dev)
- Lado: servidor
- Módulos afetados: `src/shared/Config/Enemies.luau` (tipos, elite, IA e área de teste), `Shared.Enemies` (escala e nomes), `Services/EnemyService` (pontos de spawn e renascimento)
- Remotes e validação no servidor: nenhum
- Dados persistidos: nenhum

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):**
- **Pontos de spawn:** toda parte com a tag `EnemySpawn` é um ponto de spawn, montado no Studio. Os atributos dizem o que nasce ali:
  - `Enemy`: o tipo (`BanditThug`, `BanditArcher` ou `BanditBomber`);
  - `Count`, `Elite` e `Tier`;
  - `Zone` (`Blue`, `Yellow`, `Red` ou `Black`), que define a sorte do loot e, desde a US-029, o multiplicador de fama;
  - `RespawnTime` e `Radius`.
  O servidor deixa a parte invisível e sem colisão.
- **Área de teste:** sem pontos de spawn no place, o servidor cria a fila de teste à esquerda do spawn.
- **Escala:** `Shared.Enemies.stats` calcula a vida e o dano pelo tier e pelo elite. No T1: bandido com 468 de vida e 10,4 de dano; elite com 1.404 e 15,6; arqueiro com 312 e 8,3.

**Para o Davi testar no Studio:**
1. **Área de teste:** dê Play e vá para a esquerda do spawn. Os grupos estão a 60, 110, 160 e 210 studs.
2. **Arqueiro:** aproxime-se do segundo grupo. Ele para longe e atira; esquive no fim do aviso.
3. **Elite:** o último grupo é o bandido de elite, maior, com "Bandido de elite" em cima.
4. **Tier:** no Studio, crie uma parte com a tag `EnemySpawn` e os atributos `Enemy = BanditThug` e `Tier = 3`. Compare a barra de vida com a de um bandido da área de teste. Com um ponto de spawn no place, a área de teste não aparece.
5. **Renascer:** derrote um bandido e espere 45 s.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
