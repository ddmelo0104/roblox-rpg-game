---
tipo: historia
id: US-004
titulo: Lint e formatação automáticos
status: revisao
prioridade: should
epico: EP-001
pontos: 2
sprint:
criado: 2026-10-29
atualizado: 2026-11-04
concluido_em:
---

# US-004 · Lint e formatação automáticos

## História
**Como** desenvolvedor,
**quero** Selene (lint) e StyLua (formatação) configurados,
**para que** o código siga um padrão único sem discussão.

## Critérios de aceite
**Cenário 1: formatar ao salvar**
- **Dado** código mal formatado
- **Quando** eu salvar no VS Code
- **Então** o StyLua formata automaticamente

**Cenário 2: lint pega erro**
- **Dado** uma variável criada e nunca usada
- **Quando** eu rodar `selene src`
- **Então** o Selene acusa o problema e termina com erro

## Tarefas
- [x] `selene.toml` com `std = "roblox"`
- [x] `stylua.toml`: tabs, linha de 120 colunas, aspas duplas
- [x] Formatar ao salvar no VS Code (`.vscode/settings.json`)
- [x] GitHub Action rodando StyLua, Selene, o backlog e o build em cada push e PR

## Revisão / resultado
**Feito pelo dev (2026-11-04):** decidido **tabs** (padrão da comunidade Roblox), registrado nas convenções. Aviso do Selene também falha o CI. No ambiente do dev, o StyLua e o build do Rojo passam; o Selene não consegue baixar a definição da API do Roblox ali, então a checagem completa acontece no seu computador e no GitHub Actions.

**Para o Davi testar:**
1. Abra um `.luau`, bagunce a indentação e salve: deve voltar ao padrão.
2. Escreva `local naoUsada = 1` num arquivo em `src/` e rode `selene src`: deve aparecer `unused_variable`. Apague a linha depois.
3. Confira que o CI do primeiro push ficou verde na aba Actions do GitHub.
