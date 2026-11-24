---
tipo: historia
id: US-005
titulo: Comunicação cliente-servidor de exemplo
status: revisao
prioridade: must
epico: EP-001
pontos: 3
sprint:
criado: 2026-10-29
atualizado: 2026-11-05
concluido_em:
---

# US-005 · Comunicação cliente-servidor de exemplo

## História
**Como** arquiteto,
**quero** um exemplo de RemoteEvent em que o cliente pede uma ação e o servidor valida e responde,
**para que** esse vire o padrão de rede de todo o jogo.

## Critérios de aceite
**Cenário 1: pedido válido**
- **Dado** um jogador no servidor
- **Quando** o cliente disparar `RequestPing` com um número
- **Então** o servidor responde com o mesmo número e um timestamp

**Cenário 2: pedido inválido**
- **Dado** um cliente malicioso
- **Quando** disparar `RequestPing` com uma string ou uma tabela gigante
- **Então** o servidor ignora e registra um aviso, sem erro

## Notas técnicas
- Segue o [ADR-002](../../arquitetura/adr/ADR-002-servidor-autoritativo.md).
- Proposta implementada: Remotes criados pelo servidor em `ReplicatedStorage.Remotes`, a partir da lista em `src/shared/Remotes.luau` (aguardando o Davi).

## Tarefas
- [x] Módulo de rede com a criação e a validação dos Remotes
- [x] Exemplo `RequestPing` no servidor e no cliente
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar [VISAO-ARQUITETURAL.md](../../arquitetura/VISAO-ARQUITETURAL.md) com o padrão de rede

## Revisão / resultado
**Feito pelo dev (2026-11-05):** o Davi pediu em 05/11 para começar o código, então a história saiu do backlog direto para a implementação.
- **Lista única:** `src/shared/Remotes.luau` lista todos os Remotes, e todos são RemoteEvent. O servidor cria cada um em `ReplicatedStorage.Remotes` (`Remotes.create`, chamado no `Main` antes dos Services). O cliente pega com `Remotes.event(name)`, que espera a replicação.
- **Camada de rede do servidor:** `src/server/Network.luau` tem o `Network.onReceive(name, validate, handler)`. Primeiro aplica o limite de pedidos por segundo, por jogador e por Remote (`Config/Network`), depois o validador. O que falha vira um aviso `[Network] … rejected from …`, sem erro.
- **Validadores:** `src/shared/Validate.luau` tem `Validate.number` (tipo, NaN, infinito, faixa) e `Validate.boolean`.
- **Exemplo:** `PingService` no servidor e `PingController` no cliente.

**Decisões propostas, aguardando o Davi:**
- Os Remotes são criados pelo servidor a partir da lista no código, e não pelo `default.project.json`. Assim um Remote novo é uma linha só, junto do código que o usa.
- A rede usa Remotes puros com essa camada de validação, sem wrapper tipado externo.

**Para o Davi testar no Studio:**
1. **Cenário 1:** dê Play. O Output do cliente mostra `[Network] ping ok · 1 · server time …`.
2. **Cenário 2:** em Test → Clients and Servers (1 jogador), use a barra de comandos da janela do jogador para rodar `game.ReplicatedStorage.Remotes.RequestPing:FireServer("x")` e `game.ReplicatedStorage.Remotes.RequestPing:FireServer(table.create(10000, 1))`. O Output do servidor mostra `[Network] RequestPing rejected from …: expected number, got string` (e `…got table`), sem erro.
3. **Limite:** na mesma barra, rode `for i = 1, 50 do game.ReplicatedStorage.Remotes.RequestPing:FireServer(i) end`. O servidor responde até o limite de `Config/Network` e avisa uma vez que o jogador passou do limite.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
