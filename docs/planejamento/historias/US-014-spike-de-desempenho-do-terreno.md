---
tipo: historia
id: US-014
titulo: Spike de desempenho do terreno
status: backlog
prioridade: must
epico: EP-001
pontos: 3
sprint:
criado: 2026-11-05
atualizado: 2026-11-05
concluido_em:
---

# US-014 · Spike de desempenho do terreno

## História
**Como** arquiteto,
**quero** medir um pedaço de terreno realista de Stardawn, com vegetação e água, num PC modesto e num celular fraco,
**para que** o orçamento de desempenho e o raio de streaming estejam definidos antes de esculpir o mapa.

## Contexto
Aba [Mundo e Terreno](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f460e959-73a7): terreno realista, StreamingEnabled, modelos reaproveitados e o risco da água do Terrain. O terreno é feito no Studio (regra 5 do `CLAUDE.md`); o dev prepara as configurações do Workspace e o roteiro de medição. Stardawn é a região do M1 (decisão do Davi, 05/11).

## Critérios de aceite
**Cenário 1: medição**
- **Dado** um pedaço de terreno de Stardawn com vegetação e água
- **Quando** o jogo roda num PC modesto e num celular fraco
- **Então** FPS e memória do cliente estão anotados para os dois

**Cenário 2: decisões**
- **Dado** as medições
- **Quando** o Davi revisa
- **Então** ficam definidos o orçamento (FPS mínimo e memória máxima), o raio de streaming inicial e se a água vem do Terrain ou de planos

## Notas técnicas (arquiteto → dev)
- Lado: Studio (terreno) e projeto (configurações do Workspace no `default.project.json`)
- Módulos afetados: `default.project.json`, `src/shared/Config/` (raio e orçamento, se forem usados pelo código)
- Remotes e validação no servidor: nenhum
- Dados persistidos: nenhum

## Tarefas
- [ ] Davi: pedaço de terreno de Stardawn no Studio (heightmap e escultura)
- [ ] Dev: StreamingEnabled e raios no projeto; roteiro de medição
- [ ] Medir no PC e no celular e anotar aqui
- [ ] Atualizar a aba Mundo e Terreno com o orçamento

## Revisão / resultado
*Preenchido pelo dev ao terminar: o que foi feito, o que ficou de fora, como testar no Studio, PR.*
