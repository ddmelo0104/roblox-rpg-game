# Visão Arquitetural

Visão de alto nível de **como o jogo é construído**. Os detalhes ficam na [estrutura do repositório](ESTRUTURA-DO-REPOSITORIO.md), nas [convenções](CONVENCOES-DE-CODIGO.md) e nas decisões registradas em [`adr/`](adr/).

## Princípios
1. **O servidor é a fonte da verdade.** O cliente pede, o servidor decide. ([ADR-002](adr/ADR-002-servidor-autoritativo.md))
2. **O código fica fora do Studio.** Git + Rojo; o `.rbxl` é artefato, não fonte. ([ADR-001](adr/ADR-001-desenvolvimento-externo-com-rojo-e-git.md))
3. **Uma responsabilidade por módulo.** Cada ModuleScript resolve um problema.
4. **Dados de design separados da lógica.** Stats de itens, inimigos e zonas ficam em módulos de configuração (`src/shared/Config/`), não espalhados no código.
5. **Tipagem estrita.** Luau `--!strict` sempre que possível. ([ADR-003](adr/ADR-003-luau-em-modo-strict.md))

## Visão geral (proposta)

```mermaid
flowchart TB
  subgraph Cliente["Cliente (StarterPlayerScripts)"]
    CI[Input] --> CC[Controllers<br/>câmera, UI, efeitos]
    CC --> CN[Rede: dispara Remotes]
  end
  subgraph Compartilhado["Shared (ReplicatedStorage)"]
    SD[Dados de design<br/>itens, inimigos, fórmulas]
    ST[Tipos Luau]
    SR[Definição dos Remotes]
  end
  subgraph Servidor["Servidor (ServerScriptService)"]
    SN[Rede: valida pedidos] --> SS[Services<br/>combate, inventário, zonas]
    SS --> SP[Persistência<br/>DataStore]
  end
  CN -- RemoteEvent/Function --> SN
  SS -- estado replicado --> CC
  CC -.lê.-> SD
  SS -.lê.-> SD
```

## Camadas (proposta)
| Camada | Onde roda | Responsabilidade |
| --- | --- | --- |
| **Services** | Servidor | Regras do jogo e estado autoritativo |
| **Controllers** | Cliente | Input, câmera, UI, efeitos visuais e sonoros |
| **Shared** | Ambos | Tipos, constantes, dados de design, funções puras |
| **Rede** | Fronteira | Remotes e validação de payload |
| **Persistência** | Servidor | Salvar e carregar o perfil do jogador |

## Decisões em aberto
- [ ] Usar um framework, ou um *loader* simples do projeto, para iniciar Services e Controllers?
- [ ] Persistência: DataStore puro ou uma biblioteca com *session locking*? (ADR-005, a escrever)
- [ ] Rede: Remotes puros ou um wrapper tipado? (sai da US-005)
- [ ] Topologia do mundo: um place com tudo ou um place por zona? (ADR-004, a escrever)
- [ ] Instâncias de dungeon: no mesmo servidor ou em *reserved servers*? (ADR-007, a escrever)

A lista completa de ADRs, com o status de cada um, está no [BACKLOG.md](../planejamento/BACKLOG.md#decisões-adrs).
