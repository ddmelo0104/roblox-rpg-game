---
tipo: epico
id: EP-007
titulo: Mundo de Stardawn com cidade e 3 zonas
status: backlog
prioridade: must
marco: M1
criado: 2026-11-05
atualizado: 2026-11-05
---

# EP-007 · Mundo de Stardawn com cidade e 3 zonas

> A região de Stardawn no M1: a zona Azul de tutorial, a cidade e uma zona Amarela e uma Vermelha, num place só, com as regras de cada zona como dados.

## Objetivo
Ter um pedaço de mundo realista e otimizado onde o risco é sempre escolha do jogador.

## Contexto
Pilares 1, 3 e 4. Abas [Mundo e Terreno](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f460e959-73a7), [Zonas e Risco](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#117aa7d2-031b) e [Facções](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#84a9d09f-f75b). Stardawn é a primeira região: montanhosa, com vegetação e mais alguns elementos (decisão do Davi, 05/11). O terreno e os modelos são feitos no Studio (regra 5 do `CLAUDE.md`); o código das zonas fica no repositório.

## Escopo
**Dentro**
- Terreno realista de Stardawn pelo caminho da aba Mundo e Terreno: heightmap, escultura à mão e MaterialVariant.
- StreamingEnabled e o orçamento de desempenho medido no spike do EP-001.
- Zona Azul T1 (o tutorial), cidade (banco, vendedor e reparo), Amarela T2 (sem PvP no M1) e Vermelha T3 (PvP livre e saque total).
- Regras de cada zona como dados em `src/shared/Config/`: cor, tier, sorte e fama.
- Fronteiras, `TEMPO_COMBATE`, `PROTECAO_ENTRADA` e o aviso ao entrar numa zona de risco.
- Mapa do mundo com cor, tier e GS recomendado de cada zona.

**Fora**
- Tenebrarum e Verdantis, zona Preta e portal (M3) e coleta (M3, a confirmar).

## Critérios de conclusão
- [ ] Dá para ir da Azul à Vermelha andando, e cada zona aplica as próprias regras
- [ ] O FPS e a memória ficam dentro do orçamento do spike num PC modesto
- [ ] As regras de zona mudam só por Config, sem mudar código

## Métricas de sucesso
Num playtest, um jogador novo entende o risco das zonas sem explicação (critério de sucesso do M1).

## Dependências
- Depende de: EP-001 (spike de terreno), EP-002 e ADR-004 (topologia do mundo, a escrever)
- Bloqueia: EP-009, EP-010 e EP-012

## Riscos
> [!WARNING]
> **O mapa realista pesar demais.** Probabilidade média, impacto alto. Mitigação: orçamento medido cedo, modelos reaproveitados e pouca água do Terrain (aba Mundo e Terreno).

## Perguntas em aberto
Tempo de travessia, relevo e dia e noite estão na aba [Mundo e Terreno](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f460e959-73a7); a zona Azul (compartilhada ou instância) e o tier dela, na aba [Zonas e Risco](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#117aa7d2-031b).

## Histórias
O progresso está no [BACKLOG.md](../BACKLOG.md).

## Histórico
- 2026-11-05: épico criado com o M1, aprovado pelo Davi.
