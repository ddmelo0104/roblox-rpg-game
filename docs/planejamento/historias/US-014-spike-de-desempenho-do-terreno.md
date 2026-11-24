---
tipo: historia
id: US-014
titulo: Spike de desempenho do terreno
status: em-andamento
prioridade: must
epico: EP-001
pontos: 3
sprint:
criado: 2026-11-05
atualizado: 2026-11-23
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
- Lado: Studio (terreno e configurações de streaming do Workspace) e cliente (painel de desempenho)
- Módulos afetados: `src/client/Controllers/PerformanceController.luau` e `src/shared/Config/Debug.luau`
- Remotes e validação no servidor: nenhum
- Dados persistidos: nenhum

## Tarefas
- [ ] Davi: pedaço de terreno de Stardawn no Studio (heightmap e escultura)
- [x] Dev: painel de desempenho e roteiro de medição; StreamingEnabled e raios ficam no place (ver abaixo)
- [ ] Medir no PC e no celular e anotar aqui
- [ ] Atualizar a aba Mundo e Terreno com o orçamento

## Revisão / resultado
**Parte do dev, feita em 2026-11-23.** A história continua em andamento: faltam o terreno e a medição do Davi.
- **Painel de desempenho** (`PerformanceController`, tecla F3): mostra o FPS médio, o quadro mais lento do último segundo, a memória do cliente, o ping e as configurações de streaming. Para medir num celular, que não tem teclado, ligue `PERF_OVERLAY_VISIBLE` em `Config/Debug`.
- **Streaming no place, não no projeto:** `StreamingEnabled` e os raios são propriedades do Workspace. Não as coloquei no `default.project.json` porque não consegui confirmar daqui se o Rojo as aplica na sincronização ao vivo; ajustar direto no Studio é garantido. Ponto de partida:
  - Workspace → `StreamingEnabled` ligado, que já é o padrão do modelo Baseplate.
  - `StreamingTargetRadius` em 1024 e `StreamingMinRadius` em 64, que são os padrões do Roblox.

**Roteiro de medição:**
1. **Terreno (Davi):** um pedaço de Stardawn de uns 1000 × 1000 studs, com:
   - relevo montanhoso, por heightmap ou escultura;
   - vegetação de árvores e pedras, reaproveitando os mesmos modelos;
   - um rio ou lago com a água do Terrain;
   - uma cópia da mesma área com a água feita de planos (Parts), para comparar.
2. **Configuração:** o streaming acima e o Lighting que o jogo vai usar.
3. **Publicar:** File → Publish to Roblox, numa experiência privada de teste, para jogar no app do Roblox. Dentro do Studio, o desempenho é pior que no jogo de verdade.
4. **No PC modesto:**
   - Entre pelo app, ligue o painel (F3) e ande por um caminho fixo de 2 minutos que passe pela água e pela vegetação mais densa.
   - Anote o FPS típico, o FPS mais baixo que aparecer e a memória mais alta.
   - O Developer Console (F9, aba Memory) mostra a memória por categoria.
5. **No celular fraco:**
   - Antes de publicar, ligue `PERF_OVERLAY_VISIBLE` em `Config/Debug`.
   - Faça o mesmo caminho. Se a água do Terrain pesar, repita na área com a água em planos.
6. **Anote** na tabela abaixo. Se o celular ficar abaixo da meta, repita com um `StreamingTargetRadius` menor, por exemplo 512 e 256.

| Aparelho | Água | Raio (studs) | FPS típico | FPS mínimo | Memória máx. (MB) |
| --- | --- | --- | --- | --- | --- |
| PC modesto (modelo: ) | Terrain | 1024 | | | |
| Celular fraco (modelo: ) | Terrain | 1024 | | | |
| Celular fraco (modelo: ) | Planos | 1024 | | | |

7. **Decisão (Davi):** com os números, defina o orçamento (FPS mínimo e memória máxima), o raio de streaming inicial e o tipo de água (Terrain ou planos), e atualize a aba Mundo e Terreno.
