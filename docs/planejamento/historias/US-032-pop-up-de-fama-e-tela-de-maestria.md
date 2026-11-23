---
tipo: historia
id: US-032
titulo: Pop-up de fama e tela de maestria (PC)
status: revisao
prioridade: must
epico: EP-005
pontos: 3
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-032 · Pop-up de fama e tela de maestria (PC)

## História
**Como** jogador,
**quero** ver a fama que ganho e os níveis que subo, e uma tela com a minha maestria,
**para que** eu sinta o progresso e saiba o que falta para o próximo tier.

## Contexto
Aba [Progressão](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#31c067be-9c32), UI e feedback: pop-up "+34 fama · Espada Larga" a cada abate, efeito ao subir de nível e a tela da Árvore de Maestria. Decisões do dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)):
- **Pop-up:** mostra a fama de cada ganho, os níveis da arma e os das linhas. Os níveis das peças de armadura só aparecem na tela, porque no começo um abate sobe vários níveis de uma vez.
- **Tela:** abre na tecla N, porque o M fica para o mapa.
- **Som:** fica para o polimento do EP-011.

## Critérios de aceite
**Cenário 1: pop-up de fama**
- **Dado** um abate que dá fama
- **Quando** a fama chega
- **Então** sobe "+10 fama · Espada longa" acima do personagem

**Cenário 2: subir de nível**
- **Dado** um ganho que sobe a especialização da arma ou a maestria de uma linha
- **Quando** a fama chega
- **Então** logo depois aparece "Espada longa: especialização 5" ou "Espadas: maestria 5 · libera T2"

**Cenário 3: tela de maestria**
- **Dado** o jogador aperta N
- **Quando** a tela abre
- **Então** cada linha mostra a maestria, uma barra até o próximo nível e o próximo tier ("Libera T2 na maestria 5"), e embaixo os itens da linha com a especialização

## Notas técnicas (arquiteto → dev)
- Lado: cliente
- Módulos afetados: `FameController` (pop-ups), `MasteryUiController` (tela), `InventoryController` (cópia do progresso), `Config/Interface.MASTERY_KEY`, `Config/Items` (`LINES` e `LINE_NAMES`)
- Remotes e validação no servidor: só lê o `ProgressUpdate`
- Dados persistidos: nenhum

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):** os pop-ups usam o mesmo texto flutuante do dano. A tela de maestria fica à esquerda, para abrir junto com o inventário, e tira do modo combate para liberar o mouse. A UI final é do EP-011.

**Para o Davi testar no Studio:**
1. Derrote um bandido: sobe a fama em dourado e, no primeiro abate, os níveis em azul.
2. Aperte N: a tela mostra Espadas e Couro com maestria, as barras e "Libera T2 na maestria 5".
3. Continue derrotando: a barra enche e o nível sobe. Ao chegar a 5, aparece "· libera T2".

Passando, mude `status` para `concluido` e preencha `concluido_em`.
