---
tipo: epico
id: EP-001
titulo: Fundação do Projeto
status: em-andamento
prioridade: must
marco: M0
criado: 2026-10-29
atualizado: 2026-11-04
---

# EP-001 · Fundação do Projeto

> Deixar o ambiente de desenvolvimento profissional pronto: código fora do Studio, versionado, com padrão de qualidade e uma base cliente↔servidor funcionando.

## Objetivo
Antes de qualquer feature, garantir que cada linha de código tenha casa, padrão e histórico. Isso permite trabalhar com o Claude Code lendo e escrevendo arquivos reais, com revisão via Git.

## Contexto
Independe da visão do jogo: todo projeto precisa disso. É o que permite passar o trabalho para o Claude Code sem retrabalho.

## Escopo
**Dentro**
- Toolchain (Rokit, Rojo, Selene, StyLua, Wally)
- Repositório no GitHub e estratégia de branches
- Estrutura `src/server`, `src/client` e `src/shared`
- Comunicação cliente↔servidor de exemplo, validada no servidor
- `CLAUDE.md` e skills do projeto para o Claude Code

**Fora**
- Qualquer mecânica de jogo
- Persistência de dados (épico próprio)
- Framework de arquitetura completo (decidir em ADR quando houver necessidade)

## Critérios de conclusão
- [ ] `rojo serve` sincroniza o repositório com o Studio
- [ ] `selene src` e `stylua --check src` passam, no computador e no CI
- [ ] Um RemoteEvent de exemplo funciona e o servidor rejeita payload inválido
- [x] Repositório no GitHub com README e CLAUDE.md

## Métrica de sucesso
Do clone ao jogo rodando no Studio em menos de 10 minutos, seguindo o README.

## Dependências
- Depende de: [ADR-001](../../arquitetura/adr/ADR-001-desenvolvimento-externo-com-rojo-e-git.md) e [ADR-002](../../arquitetura/adr/ADR-002-servidor-autoritativo.md)
- Bloqueia: todos os épicos de gameplay

## Riscos
> [!WARNING]
> **Curva de aprendizado do Rojo.** Probabilidade média, impacto baixo. Mitigação: seguir o README passo a passo e registrar o que travar.

## Perguntas em aberto
- [x] O vault do Obsidian fica dentro do repositório? Não: a documentação de design virou Claude Docs, e a de engenharia mora em `docs/`. (2026-11-04)
- [x] O repositório fica privado ou público? Público, como o Davi criou (2026-11-04). Por isso, os trechos copiados de guias de terceiros e as capturas de tela ficaram fora de `docs/referencias/`.

## Histórias
O progresso está no [BACKLOG.md](../BACKLOG.md).

## Histórico
- 2026-10-29: épico criado.
- 2026-11-04: projeto passado para o Claude Code, no repositório público `ddmelo0104/roblox-rpg-game`. US-001, US-002, US-003, US-004 e US-006 implementadas pelo dev e em revisão.
