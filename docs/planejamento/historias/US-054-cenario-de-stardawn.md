---
tipo: historia
id: US-054
titulo: Cenário de Stardawn no layout de teste
status: revisao
prioridade: should
epico: EP-007
pontos: 5
sprint:
criado: 2026-11-24
atualizado: 2026-11-24
concluido_em:
---

# US-054 · Cenário de Stardawn no layout de teste

## História
**Como** jogador no mundo de teste,
**quero** um caminho, fronteiras visíveis e uma paisagem diferente em cada zona,
**para que** eu saiba para onde ir e veja que o perigo aumenta, sem precisar de explicação.

## Contexto
Pedido do Davi em 24/11: "ambientação, cidade, estruturas etc.". Até o terreno de Stardawn ser feito no Studio (Davi, EP-007), o layout de teste era um Baseplate cinza com regiões invisíveis.

A aba [Mundo e Terreno](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f460e959-73a7) define o que entra:
- **Stardawn:** "montanhosa, com vegetação e árvores grandes", com minério em abundância;
- **otimização:** decoração leve sem colisão e sem sombra;
- **borda do mapa:** "limites físicos nas bordas".

O cenário só é montado com o layout de teste das zonas e some quando o place tiver as próprias regiões. As escolhas são do dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)).

## Critérios de aceite
**Cenário 1: chão e estrada**
- **Dado** o layout de teste
- **Quando** o jogo começa
- **Então** a Azul é um campo verde, a Amarela tem grama dourada e a Vermelha, rocha escura. Uma estrada sai do spawn e passa pela cidade e por todas as zonas.

**Cenário 2: placa no spawn**
- **Dado** um jogador novo no spawn
- **Quando** ele olha a placa ao lado
- **Então** vê a direção e a distância da cidade e de cada zona ("↑ Stardawn (Cidade) · 66 m")

**Cenário 3: fronteira de risco**
- **Dado** a fronteira da Amarela com a Vermelha
- **Quando** o jogador chega pela estrada
- **Então** vê:
  - dois pilares com cristais vermelhos;
  - uma placa sobre a estrada com o nome, a cor, o tier e o resumo da zona à frente;
  - na volta, a mesma placa mostra a zona de trás;
  - postes com cristais vermelhos ao longo de toda a fronteira.

**Cenário 4: paisagem de cada zona**
- **Dado** o layout de teste
- **Quando** o jogador atravessa as zonas
- **Então** encontra:
  - na Azul, árvores grandes, algumas com flores rosa, arbustos e pedras;
  - na Amarela, colinas, ruínas, árvores e cristais rosa (o minério de Stardawn);
  - na Vermelha, picos de pedra escura, árvores secas, cristais vermelhos e torres de vigia velhas.

**Cenário 5: nada atrapalha o jogo**
- **Dado** o cenário montado
- **Quando** o jogador joga
- **Então** nada fica sobre a estrada, a cidade, os inimigos, as entradas de dungeon, os acampamentos, o baú, os bonecos ou os pontos de retorno

**Cenário 6: acampamentos e bordas**
- **Dado** um acampamento de grupo
- **Quando** o jogador chega
- **Então** vê 3 tendas e uma fogueira atrás dos inimigos. Em volta do mundo há montanhas, com neve nas mais altas, e uma parede invisível impede sair andando.

## Notas técnicas (arquiteto → dev)
- Lado: servidor
- Módulos afetados:
  - `Services/SceneryService` (novo): monta o cenário depois de todos os serviços, para saber onde está o conteúdo de teste.
  - `SceneryBuilder` (novo) e `Props`.
  - `Config/Scenery`: densidades, cores, distâncias livres e a semente.
  - `Config/Tutorial`: o último passo virou "Siga a estrada até a cidade de Stardawn".
- Desempenho:
  - cerca de 1.000 peças;
  - as montanhas ficam sempre carregadas (`Persistent`), para o horizonte não ter buracos;
  - só 8 cristais têm luz.
- Remotes: nenhum.

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima)
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-24):**
- **Repetível:** a mesma semente (`SEED`) monta sempre o mesmo cenário.
- **Distâncias livres:** cada tipo de objeto de jogo tem a sua distância livre em `AVOID_TAGS`.
- **Desligar:** `BUILD_TEST_SCENERY = false` desliga o cenário.
- **Baseplate:** o servidor pinta o Baseplate de grama só durante o jogo.

**Para o Davi testar no Studio:**
1. **Chão e placa:** dê Play e veja o campo verde, a estrada e a placa ao lado do spawn.
2. **Caminho:** siga a estrada pela cidade e pela Amarela. Confira as colinas, as ruínas e os cristais rosa.
3. **Fronteira:** aos 650 studs, veja os pilares, a placa da Zona Vermelha e os postes ao longo da fronteira.
4. **Vermelha:** confira os picos, as árvores secas e as torres de vigia.
5. **Acampamentos:** confira as tendas e a fogueira.
6. **Liberdade:** os inimigos, as entradas de dungeon e o baú continuam acessíveis.
7. **Bordas:** tente sair pelas bordas: as montanhas e a parede invisível seguram.
8. **Congelar:** na visão do servidor, copie `Workspace > Scenery`, pare, cole no `Workspace` e salve. No Play seguinte o cenário não é montado de novo.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
