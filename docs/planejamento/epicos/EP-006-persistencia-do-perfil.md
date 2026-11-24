---
tipo: epico
id: EP-006
titulo: Persistência do perfil com session locking
status: em-andamento
prioridade: must
marco: M1
criado: 2026-11-05
atualizado: 2026-11-23
---

# EP-006 · Persistência do perfil com session locking

> Salvar e carregar o perfil do jogador (inventário, banco, fama e maestria) sem perder nem duplicar nada.

## Objetivo
Garantir que o progresso e os itens sobrevivam a quedas, trocas de servidor e saídas no meio do combate.

## Contexto
Pilar 3: o progresso nunca se perde, só itens e loot. Segue a regra 6 do `CLAUDE.md`. Regras de *combat logging* na aba [Zonas e Risco](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#117aa7d2-031b).

## Escopo
**Dentro**
- Escolher entre DataStore puro e uma biblioteca com *session locking* ([ADR-005](../../arquitetura/adr/ADR-005-perfil-salvo-com-trava-de-sessao.md), proposto em 23/11).
- Perfil versionado, salvo ao sair e periodicamente.
- Quem sai em combate numa zona de risco deixa o personagem 30 s no mundo, e o perfil só é liberado depois disso.
- Inventário e banco no perfil, ligados aos `uid` do EP-004.

**Fora**
- Mercado entre servidores (M2).

## Critérios de conclusão
- [ ] Sair e entrar mantém inventário, banco, fama e maestria
- [ ] Abrir o mesmo perfil em dois servidores ao mesmo tempo não duplica itens
- [ ] Sair no meio do combate segue a regra dos 30 s

## Métricas de sucesso
Nenhum perfil perdido e nenhum item duplicado nos testes de queda e de troca de servidor.

## Dependências
- Depende de: EP-001 e ADR-005 (proposto)
- Bloqueia: guardar o que os EP-004, EP-005 e EP-009 produzem

## Riscos
> [!WARNING]
> **Perda de dados nos limites do DataStore.** Probabilidade média, impacto altíssimo. Mitigação: biblioteca com *session locking*, novas tentativas e testes de queda.

## Perguntas em aberto
A biblioteca de persistência é o [ADR-005](../../arquitetura/adr/ADR-005-perfil-salvo-com-trava-de-sessao.md), proposto pelo dev e esperando o Davi.

## Histórias
Criadas pelo dev em 23/11, por delegação do Davi, seguindo o [ADR-005](../../arquitetura/adr/ADR-005-perfil-salvo-com-trava-de-sessao.md) (proposto).

| História | Depende de |
| --- | --- |
| [US-033 · Perfil salvo com trava de sessão](../historias/US-033-perfil-salvo-com-trava-de-sessao.md) | ADR-005 |
| [US-034 · Inventário e fama no perfil, sem duplicar itens](../historias/US-034-inventario-e-fama-no-perfil.md) | US-033, US-017, US-029 |

**Ainda a escrever:**
- A regra dos 30 s para quem sai em combate numa zona de risco. Ela depende das zonas (EP-007) e do derrubado e do saque (EP-009).
- O banco, que vem com a cidade (EP-007).

O progresso está no [BACKLOG.md](../BACKLOG.md).

## Histórico
- 2026-11-05: épico criado com o M1, aprovado pelo Davi.
