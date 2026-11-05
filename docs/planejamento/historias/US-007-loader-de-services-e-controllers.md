---
tipo: historia
id: US-007
titulo: Loader de Services e Controllers
status: backlog
prioridade: must
epico: EP-001
pontos: 2
sprint:
criado: 2026-11-05
atualizado: 2026-11-05
concluido_em:
---

# US-007 · Loader de Services e Controllers

## História
**Como** dev,
**quero** que o servidor e o cliente iniciem sozinhos cada Service e cada Controller,
**para que** um sistema novo seja só um módulo novo, sem mexer no `Main`.

## Contexto
Primeira peça da base de código do [EP-001](../epicos/EP-001-base-tecnica-e-prototipo-do-nucleo.md). Na [visão arquitetural](../../arquitetura/VISAO-ARQUITETURAL.md) está em aberto se o projeto usa um framework ou um *loader* simples. Proposta do dev: um loader simples do projeto, sem dependência externa, fácil de trocar por um framework depois.

## Critérios de aceite
**Cenário 1: Services iniciam**
- **Dado** ModuleScripts em `src/server/Services` com `Init` e `Start`
- **Quando** o servidor inicia
- **Então** o `Init` de todos roda antes de qualquer `Start`, e o Output mostra `[Main] servidor ok` com a lista de Services

**Cenário 2: Controllers iniciam**
- **Dado** ModuleScripts em `src/client/Controllers`
- **Quando** o cliente entra
- **Então** acontece o mesmo, e o Output mostra `[Main] cliente ok` com a lista de Controllers

**Cenário 3: erro isolado**
- **Dado** um módulo que dá erro no `Init` ou no `Start`
- **Quando** o jogo inicia
- **Então** os outros continuam funcionando, e o erro aparece no Output com o nome do módulo

## Notas técnicas (arquiteto → dev)
- Lado: servidor e cliente
- Módulos afetados: `src/shared/Loader.luau` (novo), `src/server/Main.server.luau`, `src/client/Main.client.luau`, pastas `src/server/Services/` e `src/client/Controllers/`
- Contrato: cada módulo devolve uma tabela com `Init` e `Start` opcionais, definidos com `:`
- Remotes e validação no servidor: nenhum
- Dados persistidos: nenhum
- ADRs relevantes: [ADR-003](../../arquitetura/adr/ADR-003-luau-em-modo-strict.md)

## Tarefas
- [ ] `Loader.iniciar(pasta, rotulo)` com as duas fases e `pcall` por módulo
- [ ] `Main` do servidor e do cliente usando o loader
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [ ] Registrar a proposta do loader na visão arquitetural

## Revisão / resultado
*Preenchido pelo dev ao terminar: o que foi feito, o que ficou de fora, como testar no Studio, PR.*
