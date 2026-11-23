---
tipo: historia
id: US-047
titulo: Acampamentos para grupos de 2 a 4
status: revisao
prioridade: must
epico: EP-012
pontos: 3
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-047 · Acampamentos para grupos de 2 a 4

## História
**Como** grupo,
**quero** acampamentos de inimigos fortes no mundo, que deixam um baú quando limpos,
**para que** a gente tenha conteúdo de grupo no mundo aberto (Pilar 1).

## Contexto
Aba [Dungeons](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#1f67c338-4738): acampamentos para grupos de 2 a 4, fixos no mapa e sem entrada (Davi, 04/11). As regras de morte são as da zona. Decisões do dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)):
- **Inimigos:** elites que voltam todos juntos 150 s depois de o acampamento ser limpo.
- **Baú:** 3 itens, dividido entre quem lutou lá (e o grupo) e está a até 60 studs.
- **Teste:** um acampamento na Amarela e um na Vermelha de teste.

## Critérios de aceite
**Cenário 1: limpar**
- **Dado** um acampamento com 2 bandidos de elite, 1 arqueiro de elite e 1 bandido com pólvora
- **Quando** o grupo derrota todos
- **Então** aparece um baú, que só quem lutou lá pode abrir

**Cenário 2: baú dividido**
- **Dado** dois jogadores que lutaram no acampamento, perto do baú
- **Quando** um deles abre
- **Então** os 3 itens são divididos entre os dois

**Cenário 3: voltar**
- **Dado** um acampamento limpo
- **Quando** passam 150 s
- **Então** todos os inimigos voltam juntos

## Notas técnicas (arquiteto → dev)
- Lado: servidor
- Módulos afetados: `Services/CampService` (novo), `Config/Camps` (novo), `src/server/SplitChest.luau` (o baú dividido, reaproveitado das dungeons), `EnemyService.livingAt` e `EnemyService.respawn`
- Remotes e validação no servidor: o prompt do baú confere quem lutou no acampamento e a distância
- Dados persistidos: nenhum

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):**
- **Acampamento no Studio:** é uma pasta ou modelo com a tag `Camp`, contendo pontos de spawn com `Respawns = false` e, se quiser, uma parte `ChestAnchor`.
- **Volta do acampamento:** o `CampService` acompanha os abates e põe o baú. Depois traz o acampamento de volta com `EnemyService.respawn`.
- **Pontos de teste:** os acampamentos de teste marcam os pontos com `TestContent`, para a fileira de inimigos de teste continuar aparecendo.

**Para o Davi testar no Studio:**
1. **Encontrar:** os acampamentos de teste ficam 150 studs à frente da fileira de inimigos: um na Amarela (530 studs à esquerda) e outro na Vermelha (790 studs).
2. **Limpar:** derrote todos (é difícil sozinho). Aparece um baú; segure G: 3 itens.
3. **Voltar:** espere 150 s. Os inimigos voltam.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
