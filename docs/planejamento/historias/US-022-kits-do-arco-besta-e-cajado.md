---
tipo: historia
id: US-022
titulo: Kits do arco, da besta e do cajado de fogo
status: revisao
prioridade: must
epico: EP-003
pontos: 5
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-022 · Kits do arco, da besta e do cajado de fogo

## História
**Como** jogador,
**quero** que o arco, a besta e o cajado de fogo tenham habilidades próprias,
**para que** dê para jogar de longe e como mago.

## Contexto
Aba [Combate e Habilidades](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f0d54cbd-810d): os tipos de habilidade são no alvo, em direção, em área no chão e em volta de si. As habilidades de dano à distância custam mais energia, para segurar magos e rangers. Os kits foram decididos pelo dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)):
- **Arco:** Flecha perfurante (linha), Tiro certeiro (alvo) e Chuva de flechas (área no chão).
- **Besta:** Virote pesado (alvo), Rajada (linha larga) e Tiro explosivo (área no chão).
- **Cajado de fogo:** Bola de fogo (alvo), Onda de chamas (cone largo) e Coluna de fogo (área no chão).

## Critérios de aceite
**Cenário 1: área no chão**
- **Dado** o Arco equipado e um boneco travado a 30 studs
- **Quando** o jogador usa a Chuva de flechas (R)
- **Então** um círculo cai sob o boneco e acerta todos dentro dele

**Cenário 2: área sem alvo**
- **Dado** nenhum alvo travado
- **Quando** o jogador usa uma área no chão
- **Então** ela cai à frente, no alcance máximo da habilidade

**Cenário 3: longe demais**
- **Dado** um ponto pedido além do alcance
- **Quando** o pedido chega ao servidor
- **Então** o servidor recusa ("fora de alcance")

## Notas técnicas (arquiteto → dev)
- Lado: servidor e cliente
- Módulos afetados: `src/shared/Config/Bow.luau`, `Crossbow.luau`, `FireStaff.luau`; forma `Ground` em `Shared.Abilities`; `CombatService`; `CombatEffectsController`
- Remotes e validação no servidor: `RequestAbility` ganhou o ponto da área no chão (`Validate.pointOrNil`), conferido contra o alcance
- Dados persistidos: nenhum

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):**
- **Forma nova `Ground`:** um círculo de raio `radius`, sob o alvo travado (se estiver no alcance) ou à frente, no alcance máximo. O servidor confere o ponto contra o alcance, com a margem de lag.
- **Kits:** as linhas e os cones reaproveitam a forma `Front` (comprimento e largura). Os custos de energia são maiores que os da espada (12 a 40, contra 10 a 25).
- **Efeitos:** um disco laranja marca a área no chão. Os números ficam nos Configs de cada arma, para ajustar jogando.

**Para o Davi testar no Studio:**
1. **Área no chão:** equipe um Arco e trave um boneco de longe (T). Aperte R: o disco cai sobre o boneco, e o número de dano sobe.
2. **Sem trava:** solte a trava e aperte R. A área cai à frente, a 40 studs.
3. **Kits:** teste Q e E de cada arma nos bonecos.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
