---
tipo: historia
id: US-007
titulo: Loader de Services e Controllers
status: revisao
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
- **Então** o `Init` de todos roda antes de qualquer `Start`, e o Output mostra `[Main] server ok` com a lista de Services

**Cenário 2: Controllers iniciam**
- **Dado** ModuleScripts em `src/client/Controllers`
- **Quando** o cliente entra
- **Então** acontece o mesmo, e o Output mostra `[Main] client ok` com a lista de Controllers

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
- [x] `Loader.start(folder, label)` com as duas fases e `pcall` por módulo
- [x] `Main` do servidor e do cliente usando o loader
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Registrar a proposta do loader na visão arquitetural

## Revisão / resultado
**Feito pelo dev (2026-11-05):** o Davi pediu para começar o código, então a história foi direto para a implementação.
- `src/shared/Loader.luau` inicia os módulos de uma pasta em duas fases: o `Init` de todos e depois o `Start` de cada um, numa thread própria. Cada chamada roda num `pcall`, e o erro sai no Output com o nome do módulo.
- O `Main` do servidor inicia a pasta `Services`, e o do cliente, a pasta `Controllers`. Os prints `[Main] server ok` e `[Main] client ok` continuam, agora com a lista de módulos.

**Decisão proposta, aguardando o Davi:** loader simples do projeto, sem framework. Trocar por um framework depois é mexer só no `Loader` e no contrato `Init`/`Start`.

**Para o Davi testar no Studio:**
1. Rode `rojo serve`, conecte o Studio e dê Play.
2. **Cenários 1 e 2:** o Output mostra `[Main] server ok · Projeto RPG v0.0.1 · services: …` e `[Main] client ok · … · controllers: …`, com os nomes dos módulos.
3. **Cenário 3:** crie `src/server/Services/Quebrado.luau` com `return { Start = function() error("teste") end }` e dê Play. O Output mostra `[Main] erro no Start de Quebrado: …teste`, e o resto continua funcionando (a corrida da US-010, por exemplo). Apague o arquivo depois.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
