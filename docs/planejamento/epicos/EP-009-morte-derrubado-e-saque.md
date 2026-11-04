---
tipo: epico
id: EP-009
titulo: Morte, derrubado e saque
status: backlog
prioridade: must
marco: M1
criado: 2026-11-05
atualizado: 2026-11-05
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
O progresso está no [BACKLOG.md](../BACKLOG.md).

## Histórico
- 2026-11-05: épico criado com o M1, aprovado pelo Davi.
