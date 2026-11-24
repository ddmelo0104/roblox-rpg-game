---
tipo: historia
id: US-053
titulo: Luz e clima de Stardawn, com a cor de cada zona
status: revisao
prioridade: should
epico: EP-007
pontos: 2
sprint:
criado: 2026-11-24
atualizado: 2026-11-24
concluido_em:
---

# US-053 · Luz e clima de Stardawn, com a cor de cada zona

## História
**Como** jogador,
**quero** que cada zona tenha a sua luz e a sua cor,
**para que** eu sinta o risco antes de ler o HUD e reconheça Stardawn só de olhar.

## Contexto
Pedido do Davi em 24/11: "ambientação". A aba [Mundo e Terreno](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f460e959-73a7) pede "iluminação e Atmosphere por zona, para dar identidade a cada uma", e o critério de sucesso do M1 é que um jogador novo entenda o risco das zonas sem explicação.

A aba deixa em aberto "ciclo de dia e noite no M1?". O dev decidiu: **sem ciclo no M1**, com Stardawn num amanhecer fixo em rosa e dourado, as cores da cidade. Os motivos:
- a luz fixa deixa a cor das zonas e as lutas fáceis de ler;
- a aba Facções já dá a cada região uma luz própria (Tenebrarum é "noite quase o tempo todo").

A decisão está no [registro de decisões delegadas](../DECISOES-DELEGADAS.md).

## Critérios de aceite
**Cenário 1: o amanhecer de Stardawn**
- **Dado** o jogo começando sem luz feita à mão
- **Quando** o jogador entra
- **Então** vê o sol baixo, a névoa rosa com brilho dourado e as nuvens rosadas, sempre na mesma hora

**Cenário 2: a cor de cada zona**
- **Dado** um jogador andando da Azul para a Vermelha
- **Quando** ele troca de zona
- **Então** a imagem muda em 2,5 s:
  - Azul: clara;
  - cidade: quente e rosada;
  - Amarela: dourada;
  - Vermelha: mais apagada, avermelhada e com mais névoa.

**Cenário 3: dungeons**
- **Dado** um jogador entrando numa dungeon
- **Quando** ele chega dentro
- **Então** a imagem fica mais escura e mais fria

**Cenário 4: luz feita à mão**
- **Dado** o atributo `ManualLighting = true` no Lighting
- **Quando** o jogo começa
- **Então** o servidor não mexe na luz, e só a cor de cada zona continua

## Notas técnicas (arquiteto → dev)
- Lado: servidor e cliente
- Módulos afetados:
  - `Services/LightingService` (novo): luz, Atmosphere, nuvens, bloom e raios de sol, uma vez no início.
  - `AmbienceController` (novo): a cor da zona, só na tela do jogador.
  - `Config/Ambience`.
  - `ZoneService` publica o atributo `ZoneIsDungeon` (`Shared/Zones`).
- Remotes: nenhum.

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima)
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-24):**
- **Valores:** todos ficam em `Config/Ambience` e são um ponto de partida para ajustar no Studio. A hora do amanhecer é `LIGHTING.ClockTime`.
- **Por zona:** a cor de cada zona e a das dungeons estão em `ZONES` e `DUNGEON`.

**Para o Davi testar no Studio:**
1. **Amanhecer:** dê Play e confira a luz, a névoa rosa e as nuvens. Se ficar escuro demais para lutar, aumente `ClockTime` ou `Brightness`.
2. **Zonas:** ande do spawn até a Vermelha e veja a cor mudar a cada fronteira.
3. **Dungeon:** entre numa dungeon (G no portal roxo) e veja a imagem escurecer; ao sair, a cor da zona volta.
4. **Luz à mão:** no Lighting, crie o atributo `ManualLighting` (booleano, ligado) e dê Play. A luz do place fica como está.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
