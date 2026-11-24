---
tipo: historia
id: US-050
titulo: Inventário detalhado e fácil de entender
status: revisao
prioridade: must
epico: EP-011
pontos: 3
sprint:
criado: 2026-11-24
atualizado: 2026-11-24
concluido_em:
---

# US-050 · Inventário detalhado e fácil de entender

## História
**Como** jogador,
**quero** um inventário que mostre tudo sobre os meus itens de um jeito claro,
**para que** eu saiba na hora o que é melhor, o que cada item faz e por que não consigo usar algum.

## Contexto
Pedido do Davi em 23/11: "faça o inventário bem intuitivo e detalhado também". A tela da US-019 era provisória: quatro slots, a mochila e 4 linhas de texto.

O que entra vem das abas [Armas e Armaduras](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#53e3dc55-5a40), [Progressão](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#31c067be-9c32) e [Combate e Habilidades](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f0d54cbd-810d): GS, tier, raridade, durabilidade, kit da arma, habilidade do peitoral, esquiva das botas, bônus da armadura e maestria pedida pelo tier. O layout é decisão do dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)).

## Critérios de aceite
**Cenário 1: equipamento**
- **Dado** o inventário aberto (I)
- **Quando** o jogador olha a coluna da esquerda
- **Então** vê:
  - os 4 slots em volta do personagem (elmo em cima, arma ao lado, peitoral no meio e botas embaixo), com o GS ao lado;
  - os atributos: vida, energia, dano, resistência e recarga;
  - as teclas do kit: ataque básico, Q, E e R da arma, C do peitoral, F da esquiva e o botão direito para aparar.

**Cenário 2: mochila**
- **Dado** itens na mochila
- **Quando** o jogador olha a coluna do meio
- **Então** vê "Mochila n/24". Cada quadrado mostra:
  - o nome e o tier;
  - a borda na cor da raridade;
  - a barra de durabilidade;
  - ▲ ou ▼ quando tem mais ou menos GS que o item equipado no mesmo slot;
  - vermelho com 🔒 quando falta maestria.

**Cenário 3: detalhes**
- **Dado** o mouse sobre um item
- **Quando** o jogador lê a coluna da direita
- **Então** vê:
  - nome, tipo, linha, tier e raridade;
  - o GS, de onde ele vem e a diferença para o equipado;
  - a durabilidade;
  - o que o item dá: ataques da arma com dano, alcance, energia e recarga; habilidade do peitoral; esquiva das botas; bônus da peça;
  - a maestria pedida;
  - o que o clique faz.

**Cenário 4: ordenar**
- **Dado** a mochila
- **Quando** o jogador clica no botão "Ordenar"
- **Então** a ordem alterna entre chegada, GS, tipo e raridade

**Cenário 5: telas menores**
- **Dado** uma tela pequena
- **Quando** o inventário abre
- **Então** ele diminui para caber, deixando espaço à esquerda para a janela de saque (US-051)

## Notas técnicas (arquiteto → dev)
- Lado: cliente
- Módulos afetados:
  - `InventoryUiController` (refeito);
  - `ItemDetails` e `ItemCell` (novos, em `src/client`, usados também pela janela de saque).
- Remotes e validação no servidor: nenhum novo. Equipar e desequipar continuam pedindo ao servidor (US-018).
- Dados persistidos: nenhum. A ordem da mochila só vale na sessão.

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima)
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-24):**
- **Tela em 3 colunas:** equipamento, mochila e detalhes.
- **Contas:** o GS e os atributos usam as mesmas contas do servidor (`Shared.Items` e `Shared.Mastery`).
- **Distâncias:** aparecem em metros, como no doc (1 stud = 0,28 m).
- **Tamanho:** a tela usa `UIScale` para caber na tela.

**Para o Davi testar no Studio:**
1. **Colunas:** dê Play e aperte I. Confira os slots em volta do personagem, o GS, os atributos e as teclas do kit.
2. **Detalhes:** pegue itens no baú de teste e passe o mouse sobre eles. Confira GS, ▲/▼, durabilidade, ataques ou habilidade e a maestria.
3. **Trava de maestria:** um item T2 ou maior sem maestria aparece vermelho com 🔒, e o detalhe diz quanto falta. Ele vem de baús e bolsas da Amarela ou da Vermelha.
4. **Ordenar:** clique em "Ordenar" e veja a mochila mudar de ordem.
5. **Equipar e guardar:** clique num item da mochila para equipar e num slot para guardar. Os números se atualizam.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
