---
tipo: epico
id: EP-009
titulo: Morte, derrubado e saque
status: em-andamento
prioridade: must
marco: M1
criado: 2026-11-05
atualizado: 2026-11-23
---

# EP-009 · Morte, derrubado e saque

> Derrubado, reanimar, finalizar e desistir conforme a zona; na Vermelha, morrer para um jogador cria a bolsa de saque total.

## Objetivo
Fazer o risco das zonas valer, sem nunca tirar o progresso.

## Contexto
Pilar 3 (punição por morte variada). Regras na aba [Zonas e Risco](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#117aa7d2-031b).

## Escopo
**Dentro**
- Estado de derrubado com os tempos por zona: levantar, reanimar (5 s) e finalizar (3 s), interrompidos por dano.
- Desistir: renasce na hora, ou conta como finalizado nas zonas de saque total.
- Saque total na Vermelha: bolsa de saque, 25% de chance de destruir cada item, 20 s de prioridade e 5 min de duração.
- Kit de recomeço e renascer no ponto de retorno da zona.
- Anti *combat logging*, junto com o EP-006.

**Fora**
- Zona Preta (M3) e reputação (M2).

## Critérios de conclusão
- [ ] Cada zona aplica a tabela de derrubado da aba Zonas e Risco
- [ ] O saque total nunca duplica nem perde item além da regra dos 25%
- [ ] Quem morre volta com o kit de recomeço

## Métricas de sucesso
Num playtest, quem morre na Vermelha entende o que perdeu e por quê.

## Dependências
- Depende de: EP-004, EP-006 e EP-007
- Bloqueia: —

## Riscos
> [!WARNING]
> **Duplicação na bolsa de saque.** Probabilidade média, impacto altíssimo. Mitigação: o item só muda de dono no servidor, pelo `uid`.

## Perguntas em aberto
Morte por monstro na Vermelha, os 25% e a moeda carregada estão na aba [Zonas e Risco](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#117aa7d2-031b).

## Histórias
Criadas pelo dev em 23/11, por delegação do Davi.

| História | Depende de |
| --- | --- |
| [US-038 · Derrubado em vez de morrer, com os tempos de cada zona](../historias/US-038-derrubado-em-vez-de-morrer.md) | US-035, US-013 |
| [US-039 · Reanimar, finalizar e desistir](../historias/US-039-reanimar-finalizar-e-desistir.md) | US-038, US-036 |
| [US-040 · Saque total na Vermelha e kit de recomeço](../historias/US-040-saque-total-e-kit-de-recomeco.md) | US-039, US-026, US-034 |
| [US-049 · Morrer numa dungeon da Zona Vermelha leva para a cidade](../historias/US-049-morrer-na-dungeon-vermelha-volta-para-a-cidade.md) (pedido do Davi, 23/11) | US-039, US-041 |

**Ainda a escrever:** o anti *combat logging* (quem sai derrubado ou em combate numa zona de risco deixa o personagem 30 s no mundo, e o perfil só é salvo e liberado depois). Ele junta este épico e o EP-006.

O progresso está no [BACKLOG.md](../BACKLOG.md).

## Histórico
- 2026-11-05: épico criado com o M1, aprovado pelo Davi.
