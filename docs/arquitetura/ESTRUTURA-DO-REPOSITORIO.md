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
    │   ├── DungeonBuilder.luau # monta as salas de uma instância de dungeon (US-041)
    │   ├── SplitChest.luau   # baú cujos itens são divididos entre jogadores (dungeons e acampamentos)
    │   ├── Teleport.luau     # teleporte para longe dentro do place (dungeons)
    │   ├── Build.luau        # peças básicas do mundo provisório: blocos, telhados, a estrela, textos e luzes (US-052)
    │   ├── Props.luau        # objetos reaproveitados: árvores, rochas, cristais, postes, estandartes, tendas (US-052, US-054)
    │   ├── CityBuilder.luau  # monta a cidade provisória de Stardawn (US-052)
    │   ├── SceneryBuilder.luau # monta o cenário do layout de teste (US-054)
    │   └── Services/         # um Service por sistema: Camp, Chest, City, Combat, CombatState, Damage, Defense, Dungeon, Enemy, Energy, Group, GroupDungeon, Inventory, Knockdown, Lighting, LootBag, LootContainer, Mastery, Movement, MovementValidation, Ping, Profile, Scenery, Stats, Status, TrainingDummy, Tutorial, Zone…
    ├── client/               # → StarterPlayer.StarterPlayerScripts.Client
    │   ├── Main.client.luau  # inicia os Controllers (Loader)
    │   ├── Notices.luau      # o último aviso para o jogador, mostrado pelo HUD
    │   ├── ItemDetails.luau  # o texto de detalhes de um item, dos atributos e do kit (US-050)
    │   ├── ItemCell.luau     # o quadrado de um item no inventário e na janela de saque (US-050)
    │   └── Controllers/      # câmera, trava de alvo, movimento, habilidades, defesa, efeitos, HUD, inventário, janela de saque, ambiente das zonas, decoração animada, fama, maestria, zona, derrubado, dungeon, mapa, tutorial, grupo, desempenho…
    ├── tools/                # → ServerStorage.WorldTools: ferramentas que rodam no Studio, fora do jogo
    │   ├── Run.luau          # o comando da barra de comandos; carrega cópias novas a cada execução (US-055)
    │   ├── WorldShape.luau   # funções puras do mundo: zona, caminho, altura e material de um ponto
    │   └── StardawnGenerator.luau # gera o terreno, as zonas, os pontos de jogo e a natureza de Stardawn
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
        ├── Zones.luau        # em que zona está um ponto, e onde o servidor publica a zona do jogador
        ├── Knockdown.luau    # onde o servidor publica que o jogador está derrubado
        ├── World.luau        # tags do mundo provisório (CityModel, Scenery) e da decoração que gira (Spin)
        ├── DungeonLayout.luau # gerador puro da dungeon: as salas a partir da semente
        ├── Loot.luau         # sorteio de raridade, tier e item
        ├── Status.luau       # atordoamento e outros estados de personagens e NPCs
        ├── CombatState.luau  # se o jogador está em combate
        └── Config/           # números e teclas de tuning (Network, Movement, Camera, Training, Combat, Longsword, Debug, Items, Progression, Loot, Interface, Armor, Bow, Crossbow, FireStaff, Enemies, Zones, Profile, Knockdown, Dungeons, Tutorial, Groups, Camps, City, Scenery, Ambience, World…)
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
