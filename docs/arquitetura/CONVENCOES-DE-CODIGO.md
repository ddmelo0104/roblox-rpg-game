# Convenções de Código

## Idioma
Decidido pelo Davi em 05/11.
- **Inglês:** todo o código e o que é ligado a ele:
  - nomes de arquivos, módulos, funções, variáveis, constantes e chaves do Config;
  - Remotes, atributos, tags do CollectionService e nomes de instâncias criadas por código;
  - comentários, mensagens de log e de erro;
  - mensagens de commit e nomes de branch.
- **Português do Brasil:** a documentação em `docs/` (histórias, ADRs, design), as descrições de PR e os textos que o jogador vê.
  - Os textos do jogador (nomes de habilidades, avisos do HUD, nome exibido dos bonecos) ficam separados do código, em constantes ou no Config, prontos para a localização no futuro.
- As variáveis das tabelas de tuning do doc de design têm nomes em português (`ENERGIA_MAX`, `MARGEM_LAG`…). No Config, elas viram nomes em inglês (`MAX_ENERGY`, `LAG_MARGIN`…), e um comentário cita o nome do doc.

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
- Antes de todo commit: `stylua src`, `selene src` e `rojo build -o roblox-rpg-game.rbxl`.

## Git
- A branch `main` está sempre jogável. Nunca use force-push na `main`.
- Uma branch por história ou bug, em inglês: `feat/US-012-longsword-abilities`, `fix/BUG-004-negative-xp`, `docs/...`, `chore/...`.
- Commits no padrão **Conventional Commits**, em inglês, citando a história:
  ```
  feat(inventory): add equip item (US-012)
  fix(combat): prevent negative damage (BUG-004)
  docs(adr): accept ADR-002
  ```
- Toda mudança entra por **pull request** para a `main`, com o template preenchido e o CI verde.

## Revisão
Toda história passa por `revisao` antes de `concluido`: o Davi lê o diff gerado pelo Claude, testa os critérios de aceite no Studio e só então marca como concluída.
