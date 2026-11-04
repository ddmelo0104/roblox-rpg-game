---
tipo: historia
id: US-005
titulo: Comunicação cliente-servidor de exemplo
status: backlog
prioridade: must
epico: EP-001
pontos: 3
sprint:
criado: 2026-10-29
atualizado: 2026-11-04
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
- A decidir: Remotes criados pelo servidor em `ReplicatedStorage.Remotes` ou definidos no `default.project.json`.

## Tarefas
- [ ] Módulo de rede com a criação e a validação dos Remotes
- [ ] Exemplo `RequestPing` no servidor e no cliente
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [ ] Atualizar [VISAO-ARQUITETURAL.md](../../arquitetura/VISAO-ARQUITETURAL.md) com o padrão de rede

## Revisão / resultado
*Preenchido pelo dev ao concluir.*
