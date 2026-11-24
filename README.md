# Projeto RPG (nome provisório)

[![CI](https://github.com/ddmelo0104/roblox-rpg-game/actions/workflows/ci.yml/badge.svg)](https://github.com/ddmelo0104/roblox-rpg-game/actions/workflows/ci.yml)

RPG de mundo aberto para Roblox, inspirado no Albion Online: zonas por risco, dungeons, loot e progressão por maestria de equipamento, sem nível de personagem.

- **Design do jogo:** [Projeto RPG · Design do Jogo](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ), no Claude Docs
- **Planejamento:** [BACKLOG.md](docs/planejamento/BACKLOG.md) e [ROADMAP.md](docs/planejamento/ROADMAP.md)
- **Arquitetura:** [visão](docs/arquitetura/VISAO-ARQUITETURAL.md), [convenções](docs/arquitetura/CONVENCOES-DE-CODIGO.md) e [ADRs](docs/arquitetura/adr/)
- **Como trabalhar com o Claude:** [docs/processo](docs/processo/COMO-TRABALHAR-COM-O-CLAUDE.md)

## Preparar o computador (uma vez)
**Jeito rápido:** com a pasta do projeto no computador (clone ou zip), rode o script de setup.
- **Windows:** dê dois cliques em `tools\setup.cmd`. Se o Windows avisar que o arquivo veio da internet, clique em **Executar**.
- **macOS:** no Terminal, dentro da pasta, rode `bash tools/setup.sh`.

O script instala o que faltar:
- o Git (só no Windows, pelo winget) e o Rokit;
- as ferramentas do `rokit.toml`;
- o plugin do Rojo no Studio;
- as extensões recomendadas do VS Code.

Depois, ele gera o place para conferir o projeto e oferece iniciar o `rojo serve`. Pode rodar de novo quando quiser, porque ele pula o que já está pronto.

**Passo a passo manual** (o mesmo que o script faz):
1. Instale o **Rokit**, que gerencia as ferramentas do projeto:
   - **Windows** (PowerShell): `Invoke-RestMethod https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | Invoke-Expression`
   - **macOS e Linux:** `curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash`
2. Clone o repositório e, dentro da pasta, rode `rokit install`. Ele instala Rojo, Selene, StyLua e Wally nas versões do `rokit.toml`.
3. Instale o plugin do Rojo no Roblox Studio com `rojo plugin install` (ou pela Creator Store).
4. Abra a pasta no VS Code e aceite as extensões recomendadas: Rojo, Luau Language Server, StyLua e Selene.

## Rodar no Studio
1. Na pasta do projeto, rode `rojo serve` (o script de setup oferece iniciar no fim).
2. No Studio, crie um place com o modelo **Baseplate**, abra o plugin do Rojo e clique em **Connect**.
3. Dê **Play**. O Output deve mostrar `[Main] server ok · Projeto RPG v0.0.1` e `[Main] client ok · Projeto RPG v0.0.1 · <seu nome>`.

## Comandos
| Comando | Para quê |
| --- | --- |
| `stylua src` | Formata o código |
| `selene src` | Lint com as regras do Roblox |
| `rojo build -o roblox-rpg-game.rbxl` | Gera o place |
| `python3 tools/backlog.py` | Atualiza o [BACKLOG.md](docs/planejamento/BACKLOG.md) (no Windows, `py tools/backlog.py`) |

O CI (GitHub Actions) roda formatação, lint, backlog e build a cada push e pull request.

## Trabalhando com o Claude Code
Abra este repositório no Claude Code. Ele lê o [CLAUDE.md](CLAUDE.md) e as skills do projeto:

| Comando | Para quê |
| --- | --- |
| `/implementar-historia US-XXX` | Implementa uma história seguindo o processo |
| `/nova-historia <título>` | Cria uma história com o próximo ID livre |
| `/novo-adr <decisão>` | Registra uma decisão técnica |

## Estrutura
```
src/server     → ServerScriptService.Server
src/client     → StarterPlayer.StarterPlayerScripts.Client
src/shared     → ReplicatedStorage.Shared
docs/          → documentação de engenharia (planejamento, arquitetura, processo)
tools/         → scripts de apoio (setup do computador e backlog)
.claude/       → skills do projeto para o Claude Code
```
Detalhes em [ESTRUTURA-DO-REPOSITORIO.md](docs/arquitetura/ESTRUTURA-DO-REPOSITORIO.md).
