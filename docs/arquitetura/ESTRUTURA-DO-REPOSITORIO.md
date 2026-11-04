# Estrutura do Repositório

```
projeto-rpg/
├── default.project.json      # mapa do Rojo: pasta → lugar no jogo
├── rokit.toml                # versões das ferramentas (rokit install)
├── selene.toml               # lint (std Roblox)
├── stylua.toml               # formatação (tabs, 120 colunas)
├── CLAUDE.md                 # contexto e regras para o Claude Code
├── README.md                 # setup e comandos
├── .claude/skills/           # skills do projeto: implementar-historia, nova-historia, novo-adr
├── .github/                  # CI e template de pull request
├── tools/backlog.py          # gera docs/planejamento/BACKLOG.md
├── docs/                     # documentação de engenharia (o design está no Claude Docs)
└── src/
    ├── server/               # → ServerScriptService.Server
    │   └── Main.server.luau
    ├── client/               # → StarterPlayer.StarterPlayerScripts.Client
    │   └── Main.client.luau
    └── shared/               # → ReplicatedStorage.Shared
        └── Projeto.luau
```

As pastas abaixo nascem com as histórias que precisarem delas:

| Pasta | Para quê |
| --- | --- |
| `src/server/Services/` | Um Service por sistema (combate, inventário, zonas…) |
| `src/client/Controllers/` | Câmera, UI, efeitos, input |
| `src/shared/Config/` | Dados de design e constantes de tuning (ex.: `Progressao.luau`, `Zonas.luau`) |
| `src/shared/Types/` | Tipos Luau compartilhados |
| `src/shared/Util/` | Funções puras (ex.: `GearScore.luau`) |
| `assets/` | Modelos `.rbxm` exportados do Studio de propósito |

## `default.project.json`
```json
{
  "name": "projeto-rpg",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": { "Shared": { "$path": "src/shared" } },
    "ServerScriptService": { "Server": { "$path": "src/server" } },
    "StarterPlayer": { "StarterPlayerScripts": { "Client": { "$path": "src/client" } } }
  }
}
```

## Nomes de arquivo no Rojo
| Arquivo | Vira no Studio |
| --- | --- |
| `Nome.server.luau` | Script (servidor) |
| `Nome.client.luau` | LocalScript (cliente) |
| `Nome.luau` | ModuleScript |
| `init.luau` dentro de uma pasta | A própria pasta vira o ModuleScript |

> [!TIP]
> Mapas, modelos e UI montados no Studio continuam sendo feitos lá. Como versioná-los (por exemplo, `.rbxm` exportados em `assets/`) fica para um ADR quando o primeiro mapa existir.
