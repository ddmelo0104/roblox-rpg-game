---
tipo: historia
id: US-013
titulo: Esquiva e parry
status: backlog
prioridade: must
epico: EP-001
pontos: 5
sprint:
criado: 2026-11-05
atualizado: 2026-11-05
concluido_em:
---

# US-013 · Esquiva e parry

## História
**Como** jogador,
**quero** esquivar e aparar golpes no tempo certo,
**para que** a minha habilidade decida a luta.

## Contexto
Aba [Combate e Habilidades](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f0d54cbd-810d): a esquiva vem das botas e existe o parry (decisões do Davi, 04/11). Ficam abertas na aba: em quais armas há parry, o que ele apara e qual a recompensa. A Visão diz que o jogo não é "combate baseado em parry": ele é uma ferramenta entre várias. No protótipo há uma esquiva só, até as botas existirem.

## Critérios de aceite
**Cenário 1: esquiva**
- **Dado** um golpe vindo na direção do jogador
- **Quando** ele esquiva a tempo
- **Então** fica invulnerável por um instante, e a esquiva entra em cooldown

**Cenário 2: parry certo**
- **Dado** um golpe corpo a corpo vindo
- **Quando** o jogador faz o parry dentro da janela
- **Então** o golpe é anulado e aparece um sinal forte

**Cenário 3: parry errado**
- **Dado** um parry fora da janela
- **Quando** o golpe chega
- **Então** o jogador fica vulnerável (proposta da aba contra parry automático)

## Notas técnicas (arquiteto → dev)
- Lado: cliente e servidor
- Módulos afetados: `src/server/Services/CombatService.luau`, `src/client/Controllers/CombatController.luau`, `src/shared/Config/Combate.luau`
- Remotes e validação no servidor: intenções de esquiva e de parry, com o tempo conferido no servidor dentro da margem de lag (ADR-009)
- Dados persistidos: nenhum
- ADRs relevantes: ADR-009 (a escrever), [ADR-002](../../arquitetura/adr/ADR-002-servidor-autoritativo.md)

## Tarefas
- [ ] Esquiva com invulnerabilidade curta e cooldown
- [ ] Parry com janela e punição por erro
- [ ] Um golpe do boneco de treino para treinar o tempo
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [ ] Atualizar a documentação afetada

## Revisão / resultado
*Preenchido pelo dev ao terminar: o que foi feito, o que ficou de fora, como testar no Studio, PR.*
