---
tipo: historia
id: US-011
titulo: Validação de movimento no servidor
status: backlog
prioridade: must
epico: EP-001
pontos: 3
sprint:
criado: 2026-11-05
atualizado: 2026-11-05
concluido_em:
---

# US-011 · Validação de movimento no servidor

## História
**Como** arquiteto,
**quero** que o servidor confira se cada personagem se desloca mais rápido do que pode e puxe de volta quem passar,
**para que** speed hack e teleporte não funcionem.

## Contexto
No Roblox, o cliente controla a física do próprio personagem. A aba [Movimentação](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#df937961-4ee9) pede a correção com margem para não punir quem está com lag. Precisa do [ADR-010](../../arquitetura/adr/ADR-010-validacao-de-movimento-no-servidor.md) (proposto em 05/11, opção B) aceito antes de implementar.

## Critérios de aceite
**Cenário 1: speed hack corrigido**
- **Dado** um cliente que muda a própria velocidade para muito acima da permitida
- **Quando** ele anda
- **Então** o servidor puxa o personagem de volta para a última posição válida e registra um aviso

**Cenário 2: lag não é punido**
- **Dado** um jogador honesto com lag simulado no Studio
- **Quando** ele anda e corre
- **Então** não há correção

**Cenário 3: teleporte do servidor não conta**
- **Dado** um teleporte feito pelo próprio servidor (renascer, por exemplo)
- **Quando** o personagem muda de lugar
- **Então** não há correção

## Notas técnicas (arquiteto → dev)
- Lado: servidor
- Módulos afetados: `src/server/Services/MovementValidationService.luau`, `src/shared/Config/Movement.luau` (margem e intervalo)
- Remotes e validação no servidor: nenhum Remote novo; usa a velocidade que o servidor decidiu na US-010
- Dados persistidos: nenhum
- ADRs relevantes: [ADR-010](../../arquitetura/adr/ADR-010-validacao-de-movimento-no-servidor.md) (proposto), [ADR-002](../../arquitetura/adr/ADR-002-servidor-autoritativo.md)

## Tarefas
- [x] Escrever o ADR-010 (proposto em 05/11)
- [ ] Aceite do Davi no ADR-010
- [ ] Conferência periódica do deslocamento horizontal, com margem e correção
- [ ] Exceção para teleportes do servidor
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [ ] Atualizar a documentação afetada

## Revisão / resultado
*Preenchido pelo dev ao terminar: o que foi feito, o que ficou de fora, como testar no Studio, PR.*
