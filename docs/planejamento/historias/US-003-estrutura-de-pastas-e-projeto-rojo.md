---
tipo: historia
id: US-003
titulo: Estrutura de pastas e projeto Rojo
status: revisao
prioridade: must
epico: EP-001
pontos: 2
sprint:
criado: 2026-10-29
atualizado: 2026-11-04
concluido_em:
---

# US-003 · Estrutura de pastas e projeto Rojo

## História
**Como** desenvolvedor,
**quero** a estrutura `src/server`, `src/client` e `src/shared` mapeada no `default.project.json`,
**para que** cada script vá automaticamente para o lugar certo no jogo.

## Critérios de aceite
**Cenário 1: script do servidor**
- **Dado** o arquivo `src/server/Main.server.luau`
- **Quando** eu der Play no Studio com o Rojo conectado
- **Então** vejo `[Main] servidor ok` no Output, e o script está em `ServerScriptService.Server`

**Cenário 2: módulo compartilhado**
- **Dado** um ModuleScript em `src/shared`
- **Quando** cliente e servidor fizerem `require` dele
- **Então** os dois funcionam, e o módulo está em `ReplicatedStorage.Shared`

## Notas técnicas
- Layout de referência em [ESTRUTURA-DO-REPOSITORIO.md](../../arquitetura/ESTRUTURA-DO-REPOSITORIO.md).

## Tarefas
- [x] `default.project.json` mapeando as três pastas
- [x] `src/server/Main.server.luau`, `src/client/Main.client.luau` e `src/shared/Projeto.luau`
- [ ] Testar no Studio (cenários acima)

## Revisão / resultado
**Feito pelo dev (2026-11-04):** o servidor e o cliente fazem `require` de `ReplicatedStorage.Shared.Projeto` e imprimem uma linha cada. O cliente usa `WaitForChild` para não depender da ordem de replicação. `rojo build` gera o place sem erros no ambiente do dev.

**Para o Davi testar:**
1. `rojo serve` na pasta do projeto e *Connect* no plugin do Rojo.
2. Play. O Output deve mostrar `[Main] servidor ok · Projeto RPG v0.0.1` e `[Main] cliente ok · Projeto RPG v0.0.1 · <seu nome>`.
3. No Explorer, confira `ServerScriptService.Server.Main`, `StarterPlayer.StarterPlayerScripts.Client.Main` e `ReplicatedStorage.Shared.Projeto`.
