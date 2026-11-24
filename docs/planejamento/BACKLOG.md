<!-- Gerado por tools/backlog.py. Não edite à mão: mude os arquivos e rode o script. -->

# Backlog

Visão geral do planejamento, montada a partir das propriedades de cada arquivo em `docs/`.
Fluxo das histórias: `backlog` → `pronto` → `em-andamento` → `revisao` → `concluido` (ou `cancelado`).
Regras de cada passagem em [Definições de Pronto](DEFINICOES-DE-PRONTO.md).

## Épicos

| Épico | Status | Prioridade | Marco | Progresso |
| --- | --- | --- | --- | --- |
| [EP-001 · Base técnica e protótipo do núcleo](epicos/EP-001-base-tecnica-e-prototipo-do-nucleo.md) | em-andamento | must | M0 | 0/15 histórias · 0/39 pts |
| [EP-002 · Personagem, câmera e controles (PC)](epicos/EP-002-personagem-camera-e-controles.md) | backlog | must | M1 | sem histórias |
| [EP-003 · Combate e habilidades por equipamento](epicos/EP-003-combate-e-habilidades.md) | em-andamento | must | M1 | 0/4 histórias · 0/16 pts |
| [EP-004 · Itens, inventário, equipamento e GS](epicos/EP-004-itens-inventario-equipamento-e-gs.md) | em-andamento | must | M1 | 0/6 histórias · 0/22 pts |
| [EP-005 · Progressão por fama, maestria e especialização](epicos/EP-005-progressao-fama-maestria-e-especializacao.md) | em-andamento | must | M1 | 0/4 histórias · 0/12 pts |
| [EP-006 · Persistência do perfil com session locking](epicos/EP-006-persistencia-do-perfil.md) | em-andamento | must | M1 | 0/2 histórias · 0/8 pts |
| [EP-007 · Mundo de Stardawn com cidade e 3 zonas](epicos/EP-007-mundo-de-stardawn.md) | em-andamento | must | M1 | 0/8 histórias · 0/36 pts |
| [EP-008 · Inimigos, IA e facções](epicos/EP-008-inimigos-ia-e-faccoes.md) | em-andamento | must | M1 | 0/4 histórias · 0/15 pts |
| [EP-009 · Morte, derrubado e saque](epicos/EP-009-morte-derrubado-e-saque.md) | em-andamento | must | M1 | 0/4 histórias · 0/16 pts |
| [EP-010 · Dungeon aleatória solo](epicos/EP-010-dungeon-aleatoria-solo.md) | em-andamento | must | M1 | 0/3 histórias · 0/13 pts |
| [EP-011 · HUD, UI e onboarding](epicos/EP-011-hud-ui-e-onboarding.md) | em-andamento | must | M1 | 0/3 histórias · 0/8 pts |
| [EP-012 · Conteúdo de grupo (dungeon de teste e acampamentos)](epicos/EP-012-conteudo-de-grupo.md) | em-andamento | must | M1 | 0/3 histórias · 0/13 pts |

## Em andamento e em revisão

| História | Status | Épico | Prioridade | Pts |
| --- | --- | --- | --- | --- |
| [US-001 · Configurar toolchain com Rokit e Rojo](historias/US-001-configurar-toolchain-com-rokit-e-rojo.md) | revisao | EP-001 | must | 2 |
| [US-002 · Criar repositório Git e GitHub](historias/US-002-criar-repositorio-git-e-github.md) | revisao | EP-001 | must | 1 |
| [US-003 · Estrutura de pastas e projeto Rojo](historias/US-003-estrutura-de-pastas-e-projeto-rojo.md) | revisao | EP-001 | must | 2 |
| [US-005 · Comunicação cliente-servidor de exemplo](historias/US-005-comunicacao-cliente-servidor-de-exemplo.md) | revisao | EP-001 | must | 3 |
| [US-007 · Loader de Services e Controllers](historias/US-007-loader-de-services-e-controllers.md) | revisao | EP-001 | must | 2 |
| [US-008 · Config tipado do protótipo](historias/US-008-config-tipado-do-prototipo.md) | revisao | EP-001 | must | 1 |
| [US-009 · Câmera em shift-lock com trava de alvo e boneco de treino](historias/US-009-camera-shift-lock-trava-de-alvo-e-boneco.md) | revisao | EP-001 | must | 5 |
| [US-010 · Corrida e pulo pedidos ao servidor](historias/US-010-corrida-e-pulo.md) | revisao | EP-001 | must | 2 |
| [US-011 · Validação de movimento no servidor](historias/US-011-validacao-de-movimento-no-servidor.md) | revisao | EP-001 | must | 3 |
| [US-012 · Três habilidades com energia e cooldown contra o boneco](historias/US-012-tres-habilidades-com-energia-e-cooldown.md) | revisao | EP-001 | must | 5 |
| [US-013 · Esquiva e parry](historias/US-013-esquiva-e-parry.md) | revisao | EP-001 | must | 5 |
| [US-014 · Spike de desempenho do terreno](historias/US-014-spike-de-desempenho-do-terreno.md) | em-andamento | EP-001 | must | 3 |
| [US-015 · Estado de combate e pulo limitado em combate](historias/US-015-estado-de-combate-e-pulo-limitado.md) | revisao | EP-001 | must | 2 |
| [US-016 · Catálogo de itens e contas de GS](historias/US-016-catalogo-de-itens-e-gs.md) | revisao | EP-004 | must | 3 |
| [US-017 · Inventário no servidor com uid e kit inicial](historias/US-017-inventario-no-servidor.md) | revisao | EP-004 | must | 3 |
| [US-018 · Equipar e desequipar, com GS e atributos do personagem](historias/US-018-equipar-gs-e-atributos.md) | revisao | EP-004 | must | 5 |
| [US-019 · Tela de inventário e equipamento (PC)](historias/US-019-tela-de-inventario.md) | revisao | EP-004 | must | 5 |
| [US-020 · Sorteio de loot e baú de teste](historias/US-020-sorteio-de-loot-e-bau-de-teste.md) | revisao | EP-004 | must | 3 |
| [US-021 · O kit de habilidades vem da arma equipada](historias/US-021-kit-vem-da-arma.md) | revisao | EP-003 | must | 3 |
| [US-022 · Kits do arco, da besta e do cajado de fogo](historias/US-022-kits-do-arco-besta-e-cajado.md) | revisao | EP-003 | must | 5 |
| [US-023 · Ataque básico com mira assistida](historias/US-023-ataque-basico-com-mira-assistida.md) | revisao | EP-003 | must | 3 |
| [US-024 · Habilidade do peitoral e esquiva pelas botas](historias/US-024-peitoral-e-botas-no-kit.md) | revisao | EP-003 | must | 5 |
| [US-025 · Inimigo com IA que percebe, persegue, ataca e volta](historias/US-025-inimigo-com-ia.md) | revisao | EP-008 | must | 5 |
| [US-026 · Crédito por dano, abate e bolsa de loot](historias/US-026-abate-e-bolsa-de-loot.md) | revisao | EP-008 | must | 5 |
| [US-027 · Tipos de inimigo, elite, escala por tier e pontos de spawn](historias/US-027-tipos-de-inimigo-elite-e-tier.md) | revisao | EP-008 | must | 3 |
| [US-028 · Inimigo que explode ao morrer](historias/US-028-inimigo-que-explode-ao-morrer.md) | revisao | EP-008 | must | 2 |
| [US-029 · Fama por abate, dividida pelo que o jogador veste](historias/US-029-fama-por-abate.md) | revisao | EP-005 | must | 5 |
| [US-030 · Especialização e maestria aumentam o GS](historias/US-030-especializacao-e-maestria-no-gs.md) | revisao | EP-005 | must | 2 |
| [US-031 · Maestria necessária para equipar tiers](historias/US-031-maestria-para-equipar-tiers.md) | revisao | EP-005 | must | 2 |
| [US-032 · Pop-up de fama e tela de maestria (PC)](historias/US-032-pop-up-de-fama-e-tela-de-maestria.md) | revisao | EP-005 | must | 3 |
| [US-033 · Perfil salvo com trava de sessão](historias/US-033-perfil-salvo-com-trava-de-sessao.md) | revisao | EP-006 | must | 5 |
| [US-034 · Inventário e fama no perfil, sem duplicar itens](historias/US-034-inventario-e-fama-no-perfil.md) | revisao | EP-006 | must | 3 |
| [US-035 · Zonas como regiões do mundo, com a zona atual no HUD](historias/US-035-zonas-como-regioes.md) | revisao | EP-007 | must | 5 |
| [US-036 · PvP na zona Vermelha](historias/US-036-pvp-na-zona-vermelha.md) | revisao | EP-007 | must | 5 |
| [US-037 · Fronteira travada em combate, proteção de entrada e aviso de risco](historias/US-037-fronteira-em-combate-e-protecao.md) | revisao | EP-007 | must | 3 |
| [US-038 · Derrubado em vez de morrer, com os tempos de cada zona](historias/US-038-derrubado-em-vez-de-morrer.md) | revisao | EP-009 | must | 5 |
| [US-039 · Reanimar, finalizar e desistir](historias/US-039-reanimar-finalizar-e-desistir.md) | revisao | EP-009 | must | 5 |
| [US-040 · Saque total na Vermelha e kit de recomeço](historias/US-040-saque-total-e-kit-de-recomeco.md) | revisao | EP-009 | must | 5 |
| [US-041 · Dungeon gerada por semente, numa instância do servidor](historias/US-041-dungeon-gerada-por-semente.md) | revisao | EP-010 | must | 5 |
| [US-042 · Entradas que aparecem e somem, e a saída da dungeon](historias/US-042-entradas-e-saida-da-dungeon.md) | revisao | EP-010 | must | 3 |
| [US-043 · Mini-chefe, chefe e baús divididos](historias/US-043-chefes-e-baus-da-dungeon.md) | revisao | EP-010 | must | 5 |
| [US-044 · Mapa do mundo com as zonas](historias/US-044-mapa-do-mundo.md) | revisao | EP-011 | must | 2 |
| [US-045 · Quest de tutorial na zona Azul](historias/US-045-quest-de-tutorial.md) | revisao | EP-011 | must | 3 |
| [US-046 · Grupo mínimo com convite, fama e bolsas divididas](historias/US-046-grupo-minimo.md) | revisao | EP-012 | must | 5 |
| [US-047 · Acampamentos para grupos de 2 a 4](historias/US-047-acampamentos-para-grupos.md) | revisao | EP-012 | must | 3 |
| [US-048 · Dungeon de grupo de teste](historias/US-048-dungeon-de-grupo-de-teste.md) | revisao | EP-012 | must | 5 |
| [US-049 · Morrer numa dungeon da Zona Vermelha leva para a cidade](historias/US-049-morrer-na-dungeon-vermelha-volta-para-a-cidade.md) | revisao | EP-009 | must | 1 |
| [US-050 · Inventário detalhado e fácil de entender](historias/US-050-inventario-detalhado.md) | revisao | EP-011 | must | 3 |
| [US-051 · Pegar os itens de baús e bolsas numa janela de saque](historias/US-051-janela-de-saque.md) | revisao | EP-004 | must | 3 |
| [US-052 · Cidade de Stardawn provisória feita por código](historias/US-052-cidade-de-stardawn.md) | revisao | EP-007 | must | 5 |
| [US-055 · Gerador do mundo de Stardawn no Studio, com relevo e zonas grandes](historias/US-055-gerador-do-mundo-de-stardawn.md) | revisao | EP-007 | must | 8 |
| [US-056 · Zonas de forma livre e cidade com quatro portões](historias/US-056-zonas-de-forma-livre.md) | revisao | EP-007 | must | 3 |
| [US-004 · Lint e formatação automáticos](historias/US-004-lint-e-formatacao-automaticos.md) | revisao | EP-001 | should | 2 |
| [US-006 · Preparar o repositório para o Claude Code](historias/US-006-preparar-o-repositorio-para-o-claude-code.md) | revisao | EP-001 | should | 1 |
| [US-053 · Luz e clima de Stardawn, com a cor de cada zona](historias/US-053-luz-e-clima-de-stardawn.md) | revisao | EP-007 | should | 2 |
| [US-054 · Cenário de Stardawn no layout de teste](historias/US-054-cenario-de-stardawn.md) | revisao | EP-007 | should | 5 |

## Prontas para começar

_Nada por aqui._

## Backlog

_Nada por aqui._

## Concluídas

_Nada por aqui._

## Decisões (ADRs)

| ADR | Status |
| --- | --- |
| [ADR-000 · Registrar decisões com ADRs](../arquitetura/adr/ADR-000-registrar-decisoes-com-adrs.md) | aceito |
| [ADR-001 · Desenvolvimento externo com Rojo e Git](../arquitetura/adr/ADR-001-desenvolvimento-externo-com-rojo-e-git.md) | aceito |
| [ADR-002 · Servidor autoritativo](../arquitetura/adr/ADR-002-servidor-autoritativo.md) | aceito |
| [ADR-003 · Luau em modo strict](../arquitetura/adr/ADR-003-luau-em-modo-strict.md) | aceito |
| [ADR-004 · Um place só no M1, com as zonas como regiões de dados](../arquitetura/adr/ADR-004-um-place-so-no-m1.md) | proposto |
| [ADR-005 · Perfil salvo no DataStore com trava de sessão própria](../arquitetura/adr/ADR-005-perfil-salvo-com-trava-de-sessao.md) | proposto |
| [ADR-006 · Itens como registros com uid gerado só no servidor](../arquitetura/adr/ADR-006-itens-como-registros-com-uid-do-servidor.md) | proposto |
| [ADR-007 · Instâncias de dungeon no mesmo servidor da zona](../arquitetura/adr/ADR-007-instancias-de-dungeon-no-mesmo-servidor.md) | proposto |
| [ADR-009 · Acerto das habilidades no servidor, com margem de lag](../arquitetura/adr/ADR-009-acerto-das-habilidades-no-servidor-com-margem-de-lag.md) | proposto |
| [ADR-010 · Validação de movimento no servidor](../arquitetura/adr/ADR-010-validacao-de-movimento-no-servidor.md) | proposto |

## Bugs abertos

_Nada por aqui._
