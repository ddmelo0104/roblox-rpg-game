---
tipo: epico
id: EP-012
titulo: Conteúdo de grupo (dungeon de teste e acampamentos)
status: em-andamento
prioridade: must
marco: M1
criado: 2026-11-05
atualizado: 2026-11-23
---

# EP-012 · Conteúdo de grupo (dungeon de teste e acampamentos)

> O conteúdo para grupos de amigos no M1: uma dungeon de grupo de teste, feita para ser clonada depois pelas áreas com variações de spawn, e os acampamentos para 2 a 4 jogadores fixos no mapa.

## Objetivo
Testar o jogo em grupo já no M1, com loot proporcional ao grupo, ou melhor, porque o conteúdo é mais difícil.

## Contexto
Pilares 1 e 2. Regra de loot solo e em grupo na aba [Dungeons](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#1f67c338-4738) (decisão do Davi, 04/11).

## Escopo
**Dentro**
- 1 dungeon de grupo de teste em Stardawn (decisão do Davi, 05/11), montada como modelo reaproveitável: salas e configuração de spawns separadas, para depois ser clonada pelas áreas com variações de spawn.
- Acampamentos para grupos de 2 a 4, fixos no mapa (decisão do Davi, 04/11).
- Loot proporcional ao grupo, ou melhor, pela dificuldade.
- Proposta: um grupo mínimo (convite e divisão de loot) já no M1; guildas continuam no M3.

**Fora**
- Espalhar as cópias da dungeon pelas outras áreas (depois do M1), dungeons aleatórias de grupo e fixas (M2) e raides (M3).

## Critérios de conclusão
- [ ] Um grupo de amigos termina a dungeon de teste, e o loot é dividido pela regra
- [ ] Trocar a configuração de spawns gera uma variação da dungeon sem mexer no código
- [ ] Os acampamentos funcionam com 2 a 4 jogadores

## Métricas de sucesso
No playtest, um grupo de amigos termina a dungeon e quer repetir.

## Dependências
- Depende de: EP-007 e EP-008; aproveita as salas e a instância do EP-010 (proposta)
- Bloqueia: —

## Riscos
> [!WARNING]
> **O escopo de grupo crescer até virar guildas.** Probabilidade média, impacto alto. Mitigação: no M1, só o grupo mínimo.

## Perguntas em aberto
Se a dungeon de grupo substitui os acampamentos, se o M1 precisa de grupo, quantos jogadores e onde a dungeon fica estão na aba [Dungeons](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#1f67c338-4738).

## Histórias
Criadas pelo dev em 23/11, por delegação do Davi. A pergunta da aba Dungeons ("a dungeon de grupo substitui os acampamentos?") ficou com a proposta: os dois, com um grupo mínimo.

| História | Depende de |
| --- | --- |
| [US-046 · Grupo mínimo com convite, fama e bolsas divididas](../historias/US-046-grupo-minimo.md) | US-029, US-026 |
| [US-047 · Acampamentos para grupos de 2 a 4](../historias/US-047-acampamentos-para-grupos.md) | US-046, US-027 |
| [US-048 · Dungeon de grupo de teste](../historias/US-048-dungeon-de-grupo-de-teste.md) | US-046, US-043 |

**Ainda a escrever:** espalhar cópias da dungeon de grupo pelas áreas (depois do M1) e a fama de grupo em baús de dungeon.

O progresso está no [BACKLOG.md](../BACKLOG.md).

## Histórico
- 2026-11-05: épico criado com o M1, aprovado pelo Davi.
