---
tipo: historia
id: US-019
titulo: Tela de inventário e equipamento (PC)
status: revisao
prioridade: must
epico: EP-004
pontos: 5
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-019 · Tela de inventário e equipamento (PC)

## História
**Como** jogador no PC,
**quero** abrir uma tela com o que visto e o que carrego,
**para que** eu possa ver os itens e equipar com um clique.

## Contexto
Aba Progressão: o jogador sempre vê o GS e o que cada item vale. A UI final é do EP-011; esta é a tela funcional do M1. Tecla provisória: I, como no Albion.

## Critérios de aceite
**Cenário 1: abrir e fechar**
- **Dado** o jogador no jogo
- **Quando** ele aperta I
- **Então** a tela abre com os 4 slots equipados, o GS e a mochila; I de novo fecha

**Cenário 2: equipar pela tela**
- **Dado** um item na mochila
- **Quando** o jogador clica nele
- **Então** o pedido vai ao servidor e a tela mostra o resultado

**Cenário 3: ver o item**
- **Dado** o mouse em cima de um item
- **Quando** ele para ali
- **Então** aparecem nome, tier, raridade, GS e bônus

## Notas técnicas (arquiteto → dev)
- Lado: cliente
- Módulos afetados: `src/client/Controllers/InventoryUiController.luau`, `src/shared/Config/Interface.luau` (tecla)
- Remotes e validação no servidor: usa `RequestEquip` e `RequestUnequip` da US-018
- Dados persistidos: nenhum
- ADRs relevantes: —

## Tarefas
- [x] Tela com equipamento, GS e mochila
- [x] Clique para equipar e desequipar
- [x] Detalhes do item ao passar o mouse
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):** `InventoryUiController`, com a tecla I (`Config/Interface`), como no Albion.
- **No alto:** os 4 slots equipados e o GS.
- **Embaixo:** a mochila, com 6 × 4 espaços. A borda de cada item tem a cor da raridade.
- **Clique:** num item da mochila, equipa; num slot equipado, desequipa.
- **Detalhes ao passar o mouse:** nome, tier, raridade, GS, bônus por peça e durabilidade.
- **Mouse livre:** abrir a tela sai do modo combate.

**Limitação:** a tela é funcional e provisória, sem arrastar. A UI final é do EP-011.

**Para o Davi testar no Studio:** aperte I para abrir. Passe o mouse e clique nos itens, como no teste da US-018, e aperte I de novo para fechar.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
