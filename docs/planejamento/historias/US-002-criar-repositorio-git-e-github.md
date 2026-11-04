---
tipo: historia
id: US-002
titulo: Criar repositório Git e GitHub
status: revisao
prioridade: must
epico: EP-001
pontos: 1
sprint:
criado: 2026-10-29
atualizado: 2026-11-04
concluido_em:
---

# US-002 · Criar repositório Git e GitHub

## História
**Como** arquiteto do projeto,
**quero** o código versionado no GitHub com `.gitignore`, README e estratégia de branches,
**para que** toda mudança seja rastreável e reversível.

## Critérios de aceite
**Cenário 1: clone limpo**
- **Dado** o repositório criado
- **Quando** eu clonar em outra pasta
- **Então** encontro README com instruções de setup e um `.gitignore` que ignora `*.rbxl`, `*.rbxlx.lock`, `Packages/` e `sourcemap.json`

**Cenário 2: fluxo de branches**
- **Dado** uma nova história
- **Quando** eu começar a trabalhar
- **Então** crio a branch `feat/US-xxx-descricao` a partir da `main`

## Tarefas
- [x] Repositório criado no GitHub pelo Davi: `ddmelo0104/roblox-rpg-game` (público)
- [x] `.gitignore`, `.gitattributes`, `.editorconfig` e `README.md`
- [x] Fluxo de branches e commits em [CONVENCOES-DE-CODIGO.md](../../arquitetura/CONVENCOES-DE-CODIGO.md)
- [x] Template de pull request em `.github/pull_request_template.md`

## Revisão / resultado
**Feito pelo dev (2026-11-04):** commit inicial com toda a estrutura enviado para a `main` de `ddmelo0104/roblox-rpg-game`. O `.gitignore` cobre places gerados, lockfiles, pacotes do Wally e o `sourcemap.json`. Como o repositório é público, a referência do Albion entrou só com resumo e links (ver `docs/referencias/`).

**Para o Davi testar:** clone o repositório em outra pasta e confira o cenário 1. O cenário 2 vale a partir da primeira história implementada no Claude Code.
