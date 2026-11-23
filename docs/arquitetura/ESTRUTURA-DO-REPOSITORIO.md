# Estrutura do Repositório

```
roblox-rpg-game/
├── default.project.json      # mapa do Rojo: pasta → lugar no jogo
├── rokit.toml                # versões das ferramentas (rokit install)
├── selene.toml               # lint (std Roblox)
├── stylua.toml               # formatação (tabs, 120 colunas)
├── CLAUDE.md                 # contexto e regras para o Claude Code
├── README.md                 # setup e comandos
├── .claude/skills/           # skills do projeto: implementar-historia, nova-historia, novo-adr
├── .github/                  # CI e template de pull request
├── tools/                    # backlog.py (gera o BACKLOG.md) e setup.cmd/.ps1/.sh (prepara o computador)
├── docs/                     # documentação de engenharia (o design está no Claude Docs)
└── src/
    ├── server/               # → ServerScriptService.Server
    │   ├── Main.server.luau  # cria os Remotes e inicia os Services (Loader)
    │   ├── Network.luau      # limite por segundo e validação de tudo que chega do cliente
    │   ├── SparringDummy.luau # comportamento do boneco que ataca (US-013)
    │   ├── EnemyBrain.luau   # a IA de um inimigo: perceber, perseguir, atacar e voltar (US-025)
    │   ├── EnemyBody.luau    # o corpo provisório dos inimigos (US-025)
    │   └── Services/         # um Service por sistema: Chest, Combat, CombatState, Damage, Defense, Enemy, Energy, Inventory, LootBag, Mastery, Movement, MovementValidation, Ping, Profile, Stats, Status, TrainingDummy…
    ├── client/               # → StarterPlayer.StarterPlayerScripts.Client
    │   ├── Main.client.luau  # inicia os Controllers (Loader)
    │   ├── Notices.luau      # o último aviso para o jogador, mostrado pelo HUD
    │   └── Controllers/      # câmera, trava de alvo, movimento, habilidades, defesa, efeitos, HUD, inventário, fama, maestria, desempenho…
    └── shared/               # → ReplicatedStorage.Shared
        ├── Project.luau
        ├── Loader.luau       # Init e Start dos Services e Controllers
        ├── Remotes.luau      # lista única dos Remotes
        ├── Validate.luau     # validadores puros do que vem do cliente
        ├── Targets.luau      # o que conta como alvo de combate, e a linha de visão
        ├── Abilities.luau    # tipos e contas da área das habilidades (cliente e servidor)
        ├── Energy.luau       # onde o servidor publica a energia de cada jogador
        ├── Defense.luau      # tipos e conta pura da esquiva e do parry
        ├── Items.luau        # tipos de item e contas de GS e atributos
        ├── Weapons.luau      # o kit de cada arma (ataque básico e 3 habilidades)
        ├── Enemies.luau      # regras puras dos inimigos: tipos, escala por tier, elite e crédito do abate
        ├── Mastery.luau      # regras puras de fama, especialização, maestria e tiers liberados
        ├── Loot.luau         # sorteio de raridade, tier e item
        ├── Status.luau       # atordoamento e outros estados de personagens e NPCs
        ├── CombatState.luau  # se o jogador está em combate
        └── Config/           # números e teclas de tuning (Network, Movement, Camera, Training, Combat, Longsword, Debug, Items, Progression, Loot, Interface, Armor, Bow, Crossbow, FireStaff, Enemies, Zones, Profile…)
```

As pastas `Services/`, `Controllers/` e `Config/` nasceram com as US-005 e US-007 a US-020. As outras nascem com as histórias que precisarem delas:

| Pasta | Para quê |
| --- | --- |
| `src/shared/Types/` | Tipos Luau compartilhados |
| `src/shared/Util/` | Funções puras (ex.: `GearScore.luau`) |
| `assets/` | Modelos `.rbxm` exportados do Studio de propósito |

## `default.project.json`
```json
{
  "name": "roblox-rpg-game",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": { "Shared": { "$path": "src/shared" } },
    "ServerScriptService": { "Server": { "$path": "src/server" } },
    "StarterPlayer": {
      "$properties": { "EnableMouseLockOption": false },
      "StarterPlayerScripts": { "Client": { "$path": "src/client" } }
    }
  }
}
```

O `EnableMouseLockOption` desligado tira o shift-lock padrão do Roblox, porque o jogo tem o próprio modo combate (US-009) e o Shift é a corrida (US-010).

## Nomes de arquivo no Rojo
| Arquivo | Vira no Studio |
| --- | --- |
| `Nome.server.luau` | Script (servidor) |
| `Nome.client.luau` | LocalScript (cliente) |
| `Nome.luau` | ModuleScript |
| `init.luau` dentro de uma pasta | A própria pasta vira o ModuleScript |

> [!TIP]
> Mapas, modelos e UI montados no Studio continuam sendo feitos lá. Como versioná-los (por exemplo, `.rbxm` exportados em `assets/`) fica para um ADR quando o primeiro mapa existir.
