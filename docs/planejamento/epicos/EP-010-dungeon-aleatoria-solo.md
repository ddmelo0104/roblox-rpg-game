---
tipo: epico
id: EP-010
titulo: Dungeon aleatória solo
status: em-andamento
prioridade: must
marco: M1
criado: 2026-11-05
atualizado: 2026-11-23
---

# EP-010 · Dungeon aleatória solo

> Dungeons procedurais solo com entradas ocultas, salas prontas, facção por zona e baús de mini-chefe e chefe.

## Objetivo
Ser a principal fonte de baús do M1 (Pilar 1), com um desafio que não se repete.

## Contexto
Pilares 1 e 2. Regras na aba [Dungeons](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#1f67c338-4738).

## Escopo
**Dentro**
- Entradas ocultas que somem depois que alguém entra.
- Gerador procedural por semente, com salas prontas montadas no Studio.
- Salas de combate, sala sorteada, mini-chefe, combate elite e chefe; modificadores sorteados (+0,1 de sorte cada).
- Saída: o portal só abre na conclusão; antes disso, dá para canalizar 30 s fora de combate (decisão do Davi).
- Aceita mais de 2 jogadores, mas o loot é dividido e pensado para 2 (decisão do Davi).
- Instância no mesmo servidor da zona (proposta A do [ADR-007](../../arquitetura/adr/ADR-007-instancias-de-dungeon-no-mesmo-servidor.md), proposto em 23/11).

**Fora**
- Dungeon corrompida, aleatória de grupo e fixa (M2) e mapas de dungeon (M2).

## Critérios de conclusão
- [ ] A mesma semente gera a mesma dungeon
- [ ] Sair, entrar ou cair não reseta nem duplica baú
- [ ] Os valores ficam em `src/shared/Config/`

## Métricas de sucesso
No playtest, uma dungeon leva o tempo da duração-alvo da aba Dungeons.

## Dependências
- Depende de: EP-007, EP-008 e [ADR-007](../../arquitetura/adr/ADR-007-instancias-de-dungeon-no-mesmo-servidor.md) (proposto)
- Bloqueia: —

## Riscos
> [!WARNING]
> **Gerador lento ou pesado.** Probabilidade média, impacto médio. Mitigação: salas prontas e gerador isolado num módulo puro, que recebe a semente.

## Perguntas em aberto
O limite de jogadores, os valores de tuning que não batem entre o doc e o vault e as facções estão na aba [Dungeons](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#1f67c338-4738).

## Histórias
Criadas pelo dev em 23/11, por delegação do Davi, seguindo o [ADR-007](../../arquitetura/adr/ADR-007-instancias-de-dungeon-no-mesmo-servidor.md) (proposto).

| História | Depende de |
| --- | --- |
| [US-041 · Dungeon gerada por semente, numa instância do servidor](../historias/US-041-dungeon-gerada-por-semente.md) | US-035, US-027 |
| [US-042 · Entradas que aparecem e somem, e a saída da dungeon](../historias/US-042-entradas-e-saida-da-dungeon.md) | US-041 |
| [US-043 · Mini-chefe, chefe e baús divididos](../historias/US-043-chefes-e-baus-da-dungeon.md) | US-041, US-029 |

**Ainda a escrever:**
- a sala de armadilha e a de evento;
- os modificadores sorteados (+0,1 de sorte cada);
- a fama de descoberta (primeira conclusão, salva no perfil);
- as salas montadas no Studio, que substituem as provisórias.

O progresso está no [BACKLOG.md](../BACKLOG.md).

## Histórico
- 2026-11-05: épico criado com o M1, aprovado pelo Davi.
