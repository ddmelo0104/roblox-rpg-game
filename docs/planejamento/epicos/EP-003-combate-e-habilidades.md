---
tipo: epico
id: EP-003
titulo: Combate e habilidades por equipamento
status: backlog
prioridade: must
marco: M1
criado: 2026-11-05
atualizado: 2026-11-05
---

# EP-003 · Combate e habilidades por equipamento

> Combate híbrido em tempo real: ataque básico com mira assistida, 3 habilidades da arma, habilidade do peitoral, esquiva das botas e parry, com energia e cooldown validados no servidor.

## Objetivo
Fazer a habilidade do jogador decidir a luta, com o kit vindo do que ele veste.

## Contexto
Pilares 2 (combate divertido) e 5 (jogue como quiser). Regras na aba [Combate e Habilidades](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f0d54cbd-810d); equipamentos na aba [Armas e Armaduras](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#53e3dc55-5a40).

## Escopo
**Dentro**
- Ataque básico com mira assistida e os quatro tipos de habilidade: no alvo, em direção, em área no chão e em volta de si.
- Energia e cooldown em todas as habilidades, contados no servidor.
- Esquiva definida pelo tipo de bota, com invulnerabilidade curta.
- Parry.
- O kit vem do equipamento: 3 habilidades da arma e a habilidade do peitoral.
- Acerto e dano calculados no servidor, com tolerância de lag (ADR-009, a escrever).
- Feedback: barra de energia, cooldowns e sinal forte de parry e de esquiva.

**Fora**
- Habilidades alternativas liberadas pela maestria (EP-005).
- Botões de celular.
- Escudos, que ficam para o M2.

## Critérios de conclusão
- [ ] As 4 armas do M1 (espada longa, besta, arco e cajado de fogo) têm 3 habilidades cada
- [ ] O servidor recusa habilidade sem energia, em cooldown, fora de alcance ou sem linha de visão
- [ ] Esquiva e parry funcionam contra monstros e entre 2 jogadores
- [ ] Os valores ficam em `src/shared/Config/` e nos dados de cada habilidade

## Métricas de sucesso
Num playtest, os jogadores usam esquiva e parry de propósito, e não só o ataque básico.

## Dependências
- Depende de: EP-002, EP-004 e ADR-009 (a escrever)
- Bloqueia: EP-008 e EP-011

## Riscos
> [!WARNING]
> **O lag deixar o combate injusto.** Probabilidade alta, impacto alto. Mitigação: efeito visual na hora no cliente, resultado no servidor, tolerância em Config e, no empate, vitória do defensor (proposta da aba).

> [!WARNING]
> **Script de parry automático.** Probabilidade média, impacto médio. Mitigação (proposta): janela curta e punição por erro.

## Perguntas em aberto
As perguntas de parry, energia, ataque básico e andar usando habilidade estão na aba [Combate e Habilidades](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f0d54cbd-810d); as habilidades de cada arma, na aba [Armas e Armaduras](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#53e3dc55-5a40).

## Histórias
O progresso está no [BACKLOG.md](../BACKLOG.md).

## Histórico
- 2026-11-05: épico criado com o M1, aprovado pelo Davi.
