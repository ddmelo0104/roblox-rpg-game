---
tipo: historia
id: US-012
titulo: Três habilidades com energia e cooldown contra o boneco
status: backlog
prioridade: must
epico: EP-001
pontos: 5
sprint:
criado: 2026-11-05
atualizado: 2026-11-05
concluido_em:
---

# US-012 · Três habilidades com energia e cooldown contra o boneco

## História
**Como** jogador,
**quero** usar 3 habilidades de uma arma, gastando energia e respeitando o cooldown, contra o boneco de treino,
**para que** eu sinta o combate e o Davi ajuste os números.

## Contexto
Aba [Combate e Habilidades](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f0d54cbd-810d): energia e cooldown em toda habilidade, e os tipos no alvo, em direção, em área e em volta de si. O protótipo usa uma arma só (risco do EP-001). Quais são as 3 habilidades de cada arma é uma pergunta aberta da aba Armas e Armaduras. Precisa do ADR-009 (acerto no servidor com tolerância de lag, a escrever).

## Critérios de aceite
**Cenário 1: habilidade acerta**
- **Dado** o jogador com energia e a habilidade fora do cooldown
- **Quando** ele usa a habilidade no boneco
- **Então** o servidor confere e aplica o dano, e o boneco perde vida

**Cenário 2: sem energia ou em cooldown**
- **Dado** o jogador sem energia, ou a habilidade em cooldown
- **Quando** ele tenta usar
- **Então** o servidor recusa e nada acontece

**Cenário 3: fora de alcance ou sem visão**
- **Dado** o boneco fora do alcance ou atrás de uma parede
- **Quando** o jogador usa uma habilidade no alvo
- **Então** o servidor recusa

**Cenário 4: feedback**
- **Dado** o jogador em combate
- **Quando** ele usa as habilidades
- **Então** vê a barra de energia e o cooldown de cada uma

## Notas técnicas (arquiteto → dev)
- Lado: cliente e servidor
- Módulos afetados: `src/shared/Config/Combate.luau`, `src/shared/Habilidades/`, `src/server/Services/CombatService.luau`, `src/client/Controllers/CombatController.luau`
- Remotes e validação no servidor: intenção de usar habilidade (id, alvo, direção ou ponto), validada pela camada de rede da US-005
- Dados persistidos: nenhum
- ADRs relevantes: ADR-009 (a escrever), [ADR-002](../../arquitetura/adr/ADR-002-servidor-autoritativo.md)

## Tarefas
- [ ] Escrever o ADR-009 (proposto) e esperar o aceite do Davi
- [ ] Definir com o Davi a arma e as 3 habilidades do protótipo
- [ ] Energia e cooldown no servidor, dano no boneco
- [ ] HUD mínimo de energia e cooldown
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [ ] Atualizar a documentação afetada

## Revisão / resultado
*Preenchido pelo dev ao terminar: o que foi feito, o que ficou de fora, como testar no Studio, PR.*
