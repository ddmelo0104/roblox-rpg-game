---
tipo: historia
id: US-055
titulo: Gerador do mundo de Stardawn no Studio, com relevo e zonas grandes
status: revisao
prioridade: must
epico: EP-007
pontos: 8
sprint:
criado: 2026-11-24
atualizado: 2026-11-24
concluido_em:
---

# US-055 · Gerador do mundo de Stardawn no Studio, com relevo e zonas grandes

## História
**Como** Davi, dono do mapa,
**quero** um gerador que monte o mundo de Stardawn no Studio, com relevo e zonas do tamanho certo,
**para que** o mapa deixe de ser um Baseplate plano e eu possa ajustar e esculpir por cima.

## Contexto
Davi, em 24/11: "gostei do design das zonas, mas elas estão muito pequenas, o mapa está plano, sem relevo algum". Depois ele escolheu:
- **Caminho:** o gerador rodado no Studio, com ele mandando prints para ajustar.
- **Tamanho:** cerca de 2,5 min a pé para atravessar cada zona.
- **Forma:** um mapa "menos quadrado, mais espalhado para os lados".

Isso responde duas perguntas da aba [Mundo e Terreno](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f460e959-73a7): o tempo de travessia (~2.400 studs a 16 studs/s) e o relevo (inventado, por gerador).

O mapa é decisão do dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)):
- a cidade fica no centro;
- a Azul é um vale ao sul, com o spawn no fundo;
- a Amarela abraça a cidade;
- a Vermelha se abre para oeste, norte e leste;
- montanhas fecham tudo.

Cada zona é a união de vários círculos (US-056), então as bordas ficam orgânicas.

O terreno e os modelos ficam no place, feitos no Studio (regra 5). O gerador é código do repositório que roda uma vez no Studio. Gerar a cada vez que o servidor liga deixaria a abertura lenta.

## Critérios de aceite
**Cenário 1: rodar**
- **Dado** o place aberto no Studio, no modo de edição, com o Rojo conectado
- **Quando** o Davi roda `require(game.ServerStorage.WorldTools.Run)()` na barra de comandos
- **Então** o Output mostra o progresso. Em um ou dois minutos o mundo está pronto, com um resumo do que foi feito.

**Cenário 2: relevo**
- **Dado** o mundo gerado
- **Quando** o Davi anda por ele
- **Então** encontra:
  - a Azul com morros suaves e grama verde;
  - a Amarela com colinas e grama dourada;
  - a Vermelha com rocha escura, cristas e picos;
  - montanhas nevadas em volta;
  - rocha nas encostas íngremes;
  - caminhos de terra batida da cidade a cada zona;
  - a cidade e o spawn em terreno plano.

**Cenário 3: tamanho e forma**
- **Dado** o mapa (M)
- **Quando** o Davi abre
- **Então** vê a cidade no centro, a Azul ao sul, a Amarela em volta e a Vermelha para os lados e o norte, com bordas redondas. Atravessar cada zona leva uns 2 a 3 minutos andando.

**Cenário 4: o jogo funciona no mundo novo**
- **Dado** o mundo gerado e salvo
- **Quando** o Davi dá Play
- **Então**:
  - nasce no fundo do vale Azul, com os bonecos e o baú de teste ao lado;
  - segue o caminho até a cidade, que é montada no platô;
  - encontra grupos de bandidos em cada zona, acampamentos na Amarela e na Vermelha, entradas de dungeon em cada zona e a dungeon de grupo na Amarela.

**Cenário 5: rodar de novo**
- **Dado** um mundo já gerado
- **Quando** o Davi roda o gerador de novo, depois de eu ajustar os números
- **Então** o mundo anterior some (pasta `StardawnWorld` e terreno) e um novo é feito, sem duplicar nada

## Notas técnicas (arquiteto → dev)
- Lado: ferramenta do Studio (não roda no jogo).
- Módulos afetados:
  - `src/tools`, sincronizado em `ServerStorage.WorldTools` (`default.project.json`):
    - `Run`: carrega cópias novas a cada execução, então o que o Rojo sincroniza vale sem reiniciar o Studio;
    - `WorldShape`: funções puras de zona, caminho, altura e material;
    - `StardawnGenerator`.
  - `Config/World`: zonas, caminhos, relevo, inimigos, acampamentos, entradas e natureza.
  - `Props` ganhou ruínas, picos e torres de vigia.
  - `Config/Dungeons`: as dungeons foram para ±16.000 studs, longe do mapa novo.
  - Os scripts de setup mostram o passo de gerar o mundo.
- Terreno: ruído do Roblox (`math.noise`) com semente fixa, escrito em pedaços de 128 × 128 studs com `WriteVoxels`, e alturas amostradas a cada 8 studs.
- O gerador também:
  - apaga o Baseplate e o que foi congelado do layout plano;
  - move a SpawnLocation para o vale Azul;
  - liga o `StreamingEnabled`, se o Studio deixar.
- Desempenho:
  - cerca de 60 milhões de studs² de zonas;
  - perto de 6 mil pedaços de terreno;
  - uns 5 mil itens de natureza (~16 mil peças);
  - 70 grupos de inimigos;
  - medir no painel F3 (US-014).

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima)
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-24):**
- **Protótipo:** testei a forma do mapa em Python antes de escrever o gerador. Os caminhos ficam todos dentro das zonas e não sobram buracos entre elas.
- **Inclinação:** a Vermelha tem cerca de 7% de terreno íngreme demais para andar.
- **O que não testei:** não consegui rodar o gerador fora do Studio. O tempo, o visual e o peso só aparecem no teste do Davi.
- **Ajustes:** todos os números ficam em `Config/World`, como `hills`, `ridges`, `SWELL_HEIGHT`, `EDGE_HEIGHT` e `SNOW_HEIGHT`.

**Para o Davi testar no Studio:**
1. **Atualizar:** rode o setup e conecte o Rojo. Se quiser manter o place plano de teste, faça antes uma cópia (Arquivo > Salvar como).
2. **Gerar:** no modo de edição, abra a barra de comandos (View > Command Bar) e rode `require(game.ServerStorage.WorldTools.Run)()`. Espere o "done" no Output e salve o place.
3. **Primeira olhada:** veja do alto, com a câmera livre do Studio, e mande prints: da cidade, do vale Azul, das colinas, dos picos e das montanhas.
4. **Jogar:** dê Play e siga o caminho do spawn até a cidade, e depois da cidade para cada zona. Abra o mapa (M).
5. **Desempenho:** ligue o painel (F3) e anote FPS e memória. Se o mundo pesar, eu reduzo a natureza ou o tamanho.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
