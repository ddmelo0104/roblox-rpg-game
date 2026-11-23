---
tipo: historia
id: US-044
titulo: Mapa do mundo com as zonas
status: revisao
prioridade: must
epico: EP-011
pontos: 2
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-044 · Mapa do mundo com as zonas

## História
**Como** jogador,
**quero** um mapa com as zonas, a cor, o tier e o GS recomendado de cada uma, e onde eu estou,
**para que** eu escolha para onde ir sabendo o risco.

## Contexto
Aba [Zonas e Risco](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#117aa7d2-031b): "O mapa do mundo mostra a cor, o tier e o GS recomendado de cada zona." Decisões do dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)): a tecla é M, e o mapa mostra só as zonas, não as entradas de dungeon (elas são ocultas, para achar explorando).

## Critérios de aceite
**Cenário 1: abrir**
- **Dado** o jogador em qualquer lugar
- **Quando** ele aperta M
- **Então** abre o mapa visto de cima, com cada zona na cor dela, o nome, o tier e o GS recomendado, e um ponto branco onde ele está

**Cenário 2: andar**
- **Dado** o mapa aberto
- **Quando** o jogador anda
- **Então** o ponto acompanha

**Cenário 3: dungeons fora**
- **Dado** o jogador numa dungeon
- **Quando** ele abre o mapa
- **Então** as regiões das dungeons não aparecem

## Notas técnicas (arquiteto → dev)
- Lado: servidor e cliente
- Módulos afetados: `ZoneService` (manda as zonas, as caixas de cada região no chão), `MapController` (novo), `Config/Interface.MAP_KEY`, `DungeonBuilder` (marca a região da dungeon)
- Remotes e validação no servidor: `ZoneMap`: aviso do servidor ao entrar e quando as regiões mudam
- Dados persistidos: nenhum

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):** o servidor manda a caixa de cada região no chão (`ZoneMap`), porque com o StreamingEnabled o cliente pode não ter as regiões longe dele. O mapa ajusta a escala para caber tudo; o norte do mapa é a frente do spawn.

**Para o Davi testar no Studio:** aperte M. Aparecem as quatro zonas de teste em fila (Azul, Cidade, Amarela e Vermelha) com o tier e o GS. Ande e veja o ponto se mover. M fecha.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
