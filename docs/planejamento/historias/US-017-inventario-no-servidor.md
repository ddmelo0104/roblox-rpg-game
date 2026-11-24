---
tipo: historia
id: US-017
titulo: Inventário no servidor com uid e kit inicial
status: revisao
prioridade: must
epico: EP-004
pontos: 3
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-017 · Inventário no servidor com uid e kit inicial

## História
**Como** jogador,
**quero** ter uma mochila e começar com um kit,
**para que** eu tenha o que vestir desde a primeira sessão e possa guardar o que encontrar.

## Contexto
Aba [Progressão](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#31c067be-9c32) e [ADR-006](../../arquitetura/adr/ADR-006-itens-como-registros-com-uid-do-servidor.md): cada item é um registro com `uid` gerado só no servidor. O kit de recomeço da aba Zonas e Risco (equipamento T1 Comum, grátis) vira o kit inicial do M1. O inventário fica só em memória até o EP-006 (persistência).

## Critérios de aceite
**Cenário 1: kit inicial**
- **Dado** um jogador que acaba de entrar
- **Quando** o personagem aparece
- **Então** ele tem uma Espada longa T1 e elmo, peitoral e botas de couro T1 equipados, e a mochila vazia

**Cenário 2: mochila cheia**
- **Dado** a mochila com 24 itens
- **Quando** o servidor tenta dar mais um item
- **Então** o item não entra e o jogador recebe um aviso

**Cenário 3: cópia para o cliente**
- **Dado** qualquer mudança no inventário
- **Quando** ela acontece no servidor
- **Então** o cliente recebe uma cópia nova para mostrar

## Notas técnicas (arquiteto → dev)
- Lado: servidor e cliente (só leitura)
- Módulos afetados: `src/server/Services/InventoryService.luau`, `src/client/Controllers/InventoryController.luau`, Remote `InventoryUpdate`
- Remotes e validação no servidor: `InventoryUpdate` só do servidor para o cliente
- Dados persistidos: nenhum por enquanto (EP-006)
- ADRs relevantes: [ADR-006](../../arquitetura/adr/ADR-006-itens-como-registros-com-uid-do-servidor.md)

## Tarefas
- [x] Registros com `uid` do servidor, mochila de 24 espaços
- [x] Kit inicial equipado
- [x] Cópia enviada ao cliente a cada mudança
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):**
- **`InventoryService`:**
  - Cada item é um registro com `uid` (`HttpService:GenerateGUID`), e a mochila tem 24 espaços.
  - Todo jogador começa com o kit inicial equipado: Espada longa e armadura de couro, T1 Comum.
  - `give()` põe itens na mochila para os baús e, depois, os drops.
- **Cópia para o cliente:** a cada mudança, o cliente recebe uma cópia (`InventoryUpdate`), que o `InventoryController` guarda.
- **Memória:** o inventário fica só em memória até o EP-006, então sair do jogo zera tudo.

**Para o Davi testar no Studio:**
1. **Kit inicial:** dê Play e aperte I. Os 4 slots estão equipados, e a mochila está vazia.
2. **Mochila cheia:** abra o baú de teste até a mochila encher (24 itens). Na vez seguinte, o aviso "Baú: mochila cheia" aparece.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
