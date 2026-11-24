---
tipo: historia
id: US-051
titulo: Pegar os itens de baús e bolsas numa janela de saque
status: revisao
prioridade: must
epico: EP-004
pontos: 3
sprint:
criado: 2026-11-24
atualizado: 2026-11-24
concluido_em:
---

# US-051 · Pegar os itens de baús e bolsas numa janela de saque

## História
**Como** jogador que abre um baú ou uma bolsa,
**quero** ver os itens numa janela e pegar o que eu quiser,
**para que** eu escolha o que levar em vez de receber tudo direto na mochila.

## Contexto
Pedido do Davi em 23/11: "os itens para que possam ser coletados dos baús ao invés de abrir e receber ele direto".

Antes, cada tipo de contêiner entregava os itens direto:
- **Baú de teste (US-020):** o item ia direto para a mochila.
- **Baús de dungeon e de acampamento (US-043, US-047, US-048):** dividiam e entregavam os itens na hora. O que não cabia na mochila ia para uma bolsa no chão; agora fica no baú até o jogador abrir espaço.
- **Bolsas no chão (US-026, US-040):** davam tudo de uma vez.

Agora os três funcionam igual, como no Albion: abrir mostra uma janela com os itens, e o jogador pega um por um ou tudo.

## Critérios de aceite
**Cenário 1: abrir**
- **Dado** um baú ou uma bolsa ao alcance
- **Quando** o jogador segura G
- **Então** abre a janela de saque à esquerda, com os itens. Cada um tem borda de raridade, durabilidade, ▲/▼ contra o equipado e 🔒 se falta maestria. O mouse em cima mostra os detalhes (US-050).

**Cenário 2: pegar um item**
- **Dado** a janela aberta
- **Quando** o jogador clica num item
- **Então** o item sai do contêiner e entra na mochila, e aparece o aviso com o nome dele

**Cenário 3: pegar tudo**
- **Dado** a janela aberta
- **Quando** o jogador clica em "Pegar tudo"
- **Então** entra tudo o que cabe. Se a mochila encher, o resto fica no contêiner e aparece "mochila cheia".

**Cenário 4: bolsa com prioridade**
- **Dado** uma bolsa com prioridade de outro jogador (20 s)
- **Quando** o jogador tenta abrir
- **Então** aparece "ainda é de quem lutou"

**Cenário 5: baú dividido**
- **Dado** um baú de chefe com 2 jogadores dentro da dungeon
- **Quando** o primeiro abre
- **Então** os itens são sorteados e divididos. Cada um vê e pega só a própria parte; quem não tem parte vê "nada aqui é seu". O baú some quando todas as partes acabam.

**Cenário 6: fechar**
- **Dado** a janela aberta
- **Quando** o jogador clica no X, se afasta, pega o último item dele, ou o contêiner some
- **Então** a janela fecha

**Cenário 7: sem duplicar**
- **Dado** dois jogadores na mesma bolsa
- **Quando** os dois clicam no mesmo item ao mesmo tempo
- **Então** só um recebe o item, e a janela do outro se atualiza sem ele

## Notas técnicas (arquiteto → dev)
- Lado: servidor e cliente
- Módulos afetados:
  - `Services/LootContainerService` (novo).
  - Passam a usar o novo serviço: `LootBagService`, `SplitChest` e `ChestService`.
  - No cliente: `LootWindowController` (novo) e `Notices` (motivo `NothingForYou`).
- Remotes e validação no servidor:
  - `ContainerView`: aviso do servidor para um jogador, com o que o contêiner guarda para ele, ou que fechou.
  - `RequestTakeItem(id, uid)` e `RequestTakeAll(id)`: o servidor confere a distância e o acesso em todo pedido.
  - `RequestCloseContainer(id)`.
  - Os ids e uids chegam como texto curto.
- Regra 6 (nenhum item em dois lugares): cada item sai do contêiner antes de entrar na mochila, sem *yield* no caminho. Se a mochila estiver cheia, ele volta para o mesmo lugar.
- Dados persistidos: nenhum. Os itens no contêiner ainda não foram para o perfil, como as bolsas de antes.

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com 2 jogadores
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-24):**
- **Serviço comum:** um contêiner diz que lista cada jogador vê (`itemsFor`), quem pode abrir (`canOpen`) e quando acabou (`isEmpty`).
- **Bolsa:** uma lista só para todos, com a prioridade de 20 s.
- **Baú dividido:** sorteia e divide os itens na primeira abertura de quem pode abrir. Daí em diante, cada jogador vê a própria parte. Quem sai do servidor perde a parte, e o baú some se não sobrar nada.
- **Baú de teste:** sorteia 1 item para a parte do jogador quando ela está vazia, com 1 s de espera entre sorteios.

**Para o Davi testar no Studio:**
1. **Baú de teste:** segure G no baú à esquerda do spawn. A janela mostra 1 item; passe o mouse e clique para pegar. A janela fecha e o aviso mostra o item.
2. **Bolsa:** em `Config/Debug`, ponha `DROP_EVERY_KILL = true`. Derrote um bandido, segure G na bolsa, pegue um item e depois "Pegar tudo".
3. **Mochila cheia:** encha a mochila (24) e clique em "Pegar tudo" numa bolsa. O que não cabe fica na janela.
4. **Fechar:** abra uma bolsa e se afaste uns passos; a janela fecha sozinha.
5. **Dois jogadores:**
   - Em Test → Clients and Servers, 2 players, mate um bandido com o primeiro. O segundo vê "ainda é de quem lutou" por 20 s.
   - Com os dois na mesma bolsa, cliquem juntos no mesmo item: só um recebe.
6. **Baú de chefe:** com 2 jogadores na dungeon de grupo, cada um vê só a própria parte. O baú some quando os dois pegam tudo.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
