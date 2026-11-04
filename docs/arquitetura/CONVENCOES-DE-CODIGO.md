# Convenções de Código

## Luau
- `--!strict` no topo de todo arquivo novo ([ADR-003](adr/ADR-003-luau-em-modo-strict.md)).
- Um bloco de comentário no topo de cada arquivo dizendo o que ele faz, e um comentário curto antes de cada função importante.
- **Módulos e classes:** `PascalCase` (`InventoryService`)
- **Funções e variáveis:** `camelCase` (`getPlayerLevel`)
- **Constantes:** `UPPER_SNAKE_CASE` (`MAX_INVENTORY_SLOTS`)
- **Privado:** prefixo `_` (`_cache`)
- Serviços do Roblox no topo: `local Players = game:GetService("Players")`.
- Nada de números mágicos: valores de balanceamento ficam em `src/shared/Config/`, com os valores iniciais das tabelas de tuning do doc de design.
- Todo `OnServerEvent` e `OnServerInvoke` **valida tipo, faixa e permissão** antes de agir ([ADR-002](adr/ADR-002-servidor-autoritativo.md)).

## Formatação e lint
- **StyLua** (`stylua.toml`): **tabs**, linha de 120 colunas, aspas duplas, parênteses sempre nas chamadas. Decidido na US-004.
- **Selene** (`selene.toml`): `std = "roblox"`. Aviso também falha o CI; se um aviso for intencional, desligue só aquela linha com um comentário `-- selene: allow(<regra>)` explicando o motivo.
- Antes de todo commit: `stylua src`, `selene src` e `rojo build -o projeto-rpg.rbxl`.

## Git
- A branch `main` está sempre jogável. Nunca use force-push na `main`.
- Uma branch por história ou bug: `feat/US-012-inventario-basico`, `fix/BUG-004-xp-negativo`, `docs/...`, `chore/...`.
- Commits no padrão **Conventional Commits**, citando a história:
  ```
  feat(inventario): adicionar equipar item (US-012)
  fix(combate): impedir dano negativo (BUG-004)
  docs(adr): aceitar ADR-002
  ```
- Toda mudança entra por **pull request** para a `main`, com o template preenchido e o CI verde.

## Revisão
Toda história passa por `revisao` antes de `concluido`: o Davi lê o diff gerado pelo Claude, testa os critérios de aceite no Studio e só então marca como concluída.
