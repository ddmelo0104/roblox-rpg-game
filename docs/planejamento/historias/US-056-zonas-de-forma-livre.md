---
tipo: historia
id: US-056
titulo: Zonas de forma livre e cidade com quatro portões
status: revisao
prioridade: must
epico: EP-007
pontos: 3
sprint:
criado: 2026-11-24
atualizado: 2026-11-24
concluido_em:
---

# US-056 · Zonas de forma livre e cidade com quatro portões

## História
**Como** jogador num mapa espalhado,
**quero** que as zonas tenham bordas orgânicas, que o mundo tenha fim e que a cidade tenha saída para todos os lados,
**para que** o mapa pareça um lugar, e não uma fila de retângulos.

## Contexto
O mapa novo da US-055 tem zonas que são uniões de círculos de até 3.300 studs, e uma peça do Roblox tem no máximo 2.048 studs por eixo. A cidade fica no centro, com zonas em volta.

Isso pedia quatro mudanças nos sistemas:
- **Regiões redondas:** um marcador com o atributo `Radius` em vez do tamanho da peça.
- **Zonas de várias partes:** atributo `ZoneId`, para que passar de um círculo a outro da mesma zona não conte como trocar de zona.
- **Fim do mundo:** sair de todas as zonas é sair do mapa.
- **Portões:** a cidade com portões nos quatro lados.

São decisões do dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)).

## Critérios de aceite
**Cenário 1: zona de várias partes**
- **Dado** um jogador andando dentro da Amarela, de um círculo para outro
- **Quando** passa pela sobreposição
- **Então** nada muda: não aparece faixa de zona nova, a proteção de entrada não recomeça e a trava de fronteira em combate não age

**Cenário 2: fim do mapa**
- **Dado** um jogador subindo as montanhas da borda
- **Quando** sai de todas as zonas
- **Então** volta ao último lugar dentro do mapa e vê "o mundo acaba aqui"

**Cenário 3: desistir em zona de várias partes**
- **Dado** um jogador derrubado numa zona de várias partes
- **Quando** desiste
- **Então** volta no ponto de retorno mais perto da mesma zona, mesmo que esteja em outro círculo

**Cenário 4: entradas por zona**
- **Dado** uma zona de vários círculos com entradas de dungeon
- **Quando** as entradas abrem
- **Então** são até 3 abertas por zona, e não por círculo

**Cenário 5: mapa**
- **Dado** o mapa (M)
- **Quando** abre
- **Então** as zonas aparecem como círculos, com o nome de cada zona escrito uma vez e a cidade por cima

**Cenário 6: quatro portões**
- **Dado** a cidade
- **Quando** o jogador chega por qualquer lado
- **Então** encontra um portão:
  - leste e oeste na rua principal;
  - sul em direção ao vale Azul;
  - norte ao lado do banco.
  - Por dentro, cada portão mostra a zona que vem depois dele.

## Notas técnicas (arquiteto → dev)
- Lado: servidor e cliente
- Módulos afetados:
  - `Shared/Zones`: `radiusOf`, `verticalSpan`, `same` e o círculo em `contains`.
  - `ZoneService`:
    - mesma zona por `ZoneId`;
    - fora do mapa devolve o jogador;
    - o mapa manda `round` e `label`.
  - `KnockdownService` (volta na mesma zona), `DungeonService` (entradas por zona) e `MapController` (círculos).
  - Cidade: `CityBuilder` e `CityService` (portões por lado, ruas por portão, texto da zona achado andando para fora), `Config/City.GATES`.
  - `Notices`: motivo `OutOfBounds`.
- Remotes: nenhum novo. O `ZoneMap` ganhou os campos `round` e `label`.

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima)
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-24):**
- **Layout plano:** continua funcionando. A cidade ganhou os portões norte e sul, que dão na borda do mapa, e a regra de fim do mapa substitui a parede invisível.
- **Regiões redondas:** usam a altura do atributo `Height` e ignoram o tamanho da peça.

**Para o Davi testar no Studio (com o mundo da US-055):**
1. **Mesma zona:** ande pela Amarela de um lado para outro. A faixa de zona só aparece ao entrar nela.
2. **Fim do mapa:** tente subir uma montanha da borda. Você volta e vê "o mundo acaba aqui".
3. **Desistir:** em 2 jogadores, derrube-se numa zona e desista. Você volta na mesma zona.
4. **Mapa:** abra o mapa (M) e confira círculos, nomes e o ponto branco.
5. **Portões:** confira os quatro portões da cidade e o texto de dentro de cada um.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
