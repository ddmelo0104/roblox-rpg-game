---
tipo: historia
id: US-001
titulo: Configurar toolchain com Rokit e Rojo
status: revisao
prioridade: must
epico: EP-001
pontos: 2
sprint:
criado: 2026-10-29
atualizado: 2026-11-04
concluido_em:
---

# US-001 · Configurar toolchain com Rokit e Rojo

## História
**Como** desenvolvedor,
**quero** instalar as ferramentas do projeto de forma versionada (Rokit gerenciando Rojo, Selene, StyLua e Wally),
**para que** qualquer máquina (minha ou a do Claude Code) tenha exatamente as mesmas versões.

## Critérios de aceite
**Cenário 1: ferramentas instaladas**
- **Dado** um clone novo do repositório
- **Quando** eu rodar `rokit install`
- **Então** `rojo --version`, `selene --version`, `stylua --version` e `wally --version` respondem

**Cenário 2: plugin do Studio**
- **Dado** o plugin do Rojo instalado no Roblox Studio
- **Quando** eu rodar `rojo serve` e clicar em *Connect*
- **Então** o Studio conecta sem erros

## Notas técnicas
- Versões fixadas no `rokit.toml` (commitado) e repetidas no CI.
- Ver [ADR-001](../../arquitetura/adr/ADR-001-desenvolvimento-externo-com-rojo-e-git.md).

## Tarefas
- [x] `rokit.toml` com Rojo 7.4.4, Selene 0.27.1, StyLua 0.20.0 e Wally 0.3.2
- [x] Passo a passo de instalação no README
- [x] Extensões recomendadas do VS Code em `.vscode/extensions.json`
- [ ] Instalar o Rokit no computador do Davi e rodar `rokit install`
- [ ] Instalar o plugin do Rojo no Studio (`rojo plugin install`)

## Revisão / resultado
**Feito pelo dev (2026-11-04):** `rokit.toml` com as quatro ferramentas em versões estáveis que funcionam juntas com o Rojo 7.4. O README traz a instalação do Rokit para Windows e para macOS/Linux. Rojo, Selene e StyLua nessas versões foram baixados e rodados no ambiente do dev.

**Para o Davi testar:** siga "Preparar o computador" no README e confira os dois cenários. Passando, mude `status` para `concluido` e preencha `concluido_em`.
