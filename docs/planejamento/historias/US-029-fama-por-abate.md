---
tipo: historia
id: US-029
titulo: Fama por abate, dividida pelo que o jogador veste
status: revisao
prioridade: must
epico: EP-005
pontos: 5
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-029 · Fama por abate, dividida pelo que o jogador veste

## História
**Como** jogador,
**quero** ganhar fama ao derrotar inimigos, e que ela vá para a arma e as peças que estou usando,
**para que** eu fique melhor naquilo que uso (Pilares 1 e 5).

## Contexto
Aba [Progressão](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#31c067be-9c32), seção Fama:
- **Fama do abate:** inimigo comum dá `10 × 1,5^(tier da zona − 1)`, e o elite dá ×3.
- **Multiplicador da zona** (aba [Zonas e Risco](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#117aa7d2-031b)): Azul ×1,0, Amarela ×1,1, Vermelha ×1,3 e Preta ×1,5.
- **Divisão por slot:** a arma recebe 100%, o peitoral 50%, e o elmo e as botas 25% cada. A maestria da linha recebe a soma do que os itens dela receberam.
- **Níveis de 0 a 100:** a curva é `2,5 × nível³`.

Decisões do dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)):
- **Roubar abate:** cada jogador com pelo menos 10% do dano recebe a fama vezes a fração dele do dano.
- **Zona:** o ponto de spawn ganhou o atributo `Zone`, que define a sorte e o multiplicador de fama no lugar de `Luck`.
- **Grupo:** a fama em grupo (+15% por membro) fica para o EP-012.

## Critérios de aceite
**Cenário 1: abate solo**
- **Dado** um jogador com a espada longa e o couro completo, numa zona Azul
- **Quando** ele derrota um bandido T1
- **Então** ganha 10 de fama: a Espada longa e a linha Espadas recebem 10, o peitoral 5, o elmo e as botas 2,5 cada, e a linha Couro 10

**Cenário 2: elite e zona**
- **Dado** um bandido de elite T1 numa zona Amarela
- **Quando** o jogador o derrota sozinho
- **Então** ganha 10 × 3 × 1,1 = 33 de fama

**Cenário 3: dividido**
- **Dado** dois jogadores, um com 70% e outro com 30% do dano
- **Quando** o inimigo cai
- **Então** o primeiro recebe 70% da fama e o segundo 30%; quem ficou abaixo de 10% não recebe

**Cenário 4: níveis**
- **Dado** um item com 312,5 de fama
- **Quando** o servidor calcula o nível
- **Então** ele está no nível 5 (`2,5 × 5³`)

**Cenário 5: reset não dá fama**
- **Dado** um inimigo que resetou (US-025)
- **Quando** ele cai depois
- **Então** só conta o dano causado depois do reset

## Notas técnicas (arquiteto → dev)
- Lado: servidor e cliente
- Módulos afetados: `Shared.Mastery` (regras puras), `Services/MasteryService`, `Services/EnemyService` (fama no abate), `Config/Progression` (números), `Config/Zones` (sorte e fama por zona), Remote `ProgressUpdate`
- Remotes e validação no servidor: nenhum pedido novo do cliente; `ProgressUpdate` é aviso do servidor com os totais e o último ganho
- Dados persistidos: ainda nenhum: o progresso some ao sair do jogo até o perfil do EP-006

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):**
- **Onde fica:** o `MasteryService` guarda a fama total de cada tipo de item (a especialização vale para qualquer cópia daquele item) e de cada linha.
- **Abate:** o `EnemyService` calcula a fama com o tier e o elite do ponto de spawn e o multiplicador da zona (`Zone`: `Blue`, `Yellow`, `Red` ou `Black`), e divide entre quem ganhou o abate.
- **Cliente:** recebe os totais e cada ganho pelo `ProgressUpdate`.

**Para o Davi testar no Studio:**
1. **Fama:** derrote um bandido da área de teste (60 studs à esquerda do spawn). Sobe "+10 fama · Espada longa".
2. **Elite:** o bandido de elite (210 studs) dá "+30 fama".
3. **Zona:** mude o atributo `Zone` de um ponto de spawn da pasta `EnemyTestArea` para `Yellow` (no servidor, durante o Play) e espere o inimigo renascer. Agora o bandido dá "+11 fama".
4. **Dividido:** com 2 jogadores (Test → Clients and Servers), batam no mesmo bandido. Cada um recebe a parte do dano que causou.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
