---
tipo: historia
id: US-026
titulo: Crédito por dano, abate e bolsa de loot
status: revisao
prioridade: must
epico: EP-008
pontos: 5
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-026 · Crédito por dano, abate e bolsa de loot

## História
**Como** jogador,
**quero** que o inimigo derrotado às vezes deixe uma bolsa com um item, guardada para quem lutou,
**para que** caçar dê loot sem que outro jogador roube o abate.

## Contexto
Aba [Progressão](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#31c067be-9c32): chance de item por abate (comum 5%, elite 25%), com tier e raridade pelo sorteio da US-020 (sorte da zona); contra "roubar abate", o crédito vai pela contribuição de dano, com mínimo de 10%. Aba [Zonas e Risco](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#117aa7d2-031b): a bolsa no chão dura 300 s, com 20 s de prioridade. O dev reaproveitou essa bolsa para o loot de inimigo ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)).

## Critérios de aceite
**Cenário 1: bolsa**
- **Dado** um jogador derrota um inimigo e o sorteio dá item
- **Quando** o inimigo cai
- **Então** uma bolsa aparece no lugar, brilhando na cor da raridade, e "Pegar" (G) põe o item na mochila

**Cenário 2: quem lutou tem prioridade**
- **Dado** um jogador que causou menos de 10% do dano
- **Quando** ele tenta pegar a bolsa nos primeiros 20 s
- **Então** o servidor recusa ("ainda é de quem lutou"); depois de 20 s, qualquer um pega

**Cenário 3: mochila cheia**
- **Dado** a mochila cheia
- **Quando** o jogador pega a bolsa
- **Então** o item fica na bolsa e aparece "mochila cheia"

**Cenário 4: some**
- **Dado** uma bolsa no chão
- **Quando** passam 300 s
- **Então** ela some, com o que tiver dentro

**Cenário 5: sem duplicar**
- **Dado** um item na bolsa
- **Quando** dois jogadores tentam pegar ao mesmo tempo
- **Então** só um recebe: o item sai da bolsa no mesmo passo em que entra na mochila

**Cenário 6: reset não dá crédito**
- **Dado** um inimigo que resetou (US-025)
- **Quando** ele é derrotado depois
- **Então** só conta o dano causado depois do reset

## Notas técnicas (arquiteto → dev)
- Lado: servidor
- Módulos afetados: `Services/DamageService` (o dano de cada jogador em cada alvo), `Services/LootBagService` (a bolsa), `Services/EnemyService` (o abate e o sorteio), `CombatService` (o dano passa pelo DamageService), `Config/Loot`, `Config/Interface` (cores de raridade e tecla G)
- Remotes e validação no servidor: a bolsa usa um ProximityPrompt; o servidor confere a distância, a prioridade e a mochila. O aviso usa o Remote `Notice`
- Dados persistidos: nenhum (a mochila ainda não é salva: EP-006)

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):**
- **Crédito:** o `DamageService` anota quanta vida cada jogador tirou de cada alvo. Ganha o abate quem tirou pelo menos 10% (`Config/Loot.KILL_CREDIT_MIN_SHARE`).
- **Sorteio:** 5% de chance de item no comum e 25% no elite. O tier e a raridade vêm do ponto de spawn (tier e sorte da zona).
- **Bolsa:** brilha na cor do melhor item. Pegar move os itens um a um, sem `yield`; o que não cabe fica na bolsa (regra 6 e ADR-006).
- **Tecla G:** a tecla de interagir com baús e bolsas virou G (`Config/Interface.INTERACT_KEY`), porque o E padrão do Roblox é tecla de habilidade. O baú de teste (US-020) também mudou.

**Para o Davi testar no Studio:**
1. **Ver uma bolsa:** ponha `DROP_EVERY_KILL = true` no `Config/Debug` (senão a chance é de 5%). Derrote um bandido: aparece a bolsa. Segure G e o item entra na mochila (I).
2. **Prioridade:** em Test → Clients and Servers com 2 jogadores, um derrota o bandido sozinho. O outro tenta pegar a bolsa logo: aparece "ainda é de quem lutou". Depois de 20 s, ele consegue.
3. **Mochila cheia:** encha a mochila no baú de teste e tente pegar uma bolsa: o item fica nela.
4. **Volte `DROP_EVERY_KILL` para `false`** no fim.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
