<!-- Gerado por tools/backlog.py. Não edite à mão: mude os arquivos e rode o script. -->

# Backlog

Visão geral do planejamento, montada a partir das propriedades de cada arquivo em `docs/`.
Fluxo das histórias: `backlog` → `pronto` → `em-andamento` → `revisao` → `concluido` (ou `cancelado`).
Regras de cada passagem em [Definições de Pronto](DEFINICOES-DE-PRONTO.md).

## Épicos

| Épico | Status | Prioridade | Marco | Progresso |
| --- | --- | --- | --- | --- |
| [EP-001 · Base técnica e protótipo do núcleo](epicos/EP-001-base-tecnica-e-prototipo-do-nucleo.md) | em-andamento | must | M0 | 0/14 histórias · 0/37 pts |
| [EP-002 · Personagem, câmera e controles (PC)](epicos/EP-002-personagem-camera-e-controles.md) | backlog | must | M1 | sem histórias |
| [EP-003 · Combate e habilidades por equipamento](epicos/EP-003-combate-e-habilidades.md) | backlog | must | M1 | sem histórias |
| [EP-004 · Itens, inventário, equipamento e GS](epicos/EP-004-itens-inventario-equipamento-e-gs.md) | backlog | must | M1 | sem histórias |
| [EP-005 · Progressão por fama, maestria e especialização](epicos/EP-005-progressao-fama-maestria-e-especializacao.md) | backlog | must | M1 | sem histórias |
| [EP-006 · Persistência do perfil com session locking](epicos/EP-006-persistencia-do-perfil.md) | backlog | must | M1 | sem histórias |
| [EP-007 · Mundo de Stardawn com cidade e 3 zonas](epicos/EP-007-mundo-de-stardawn.md) | backlog | must | M1 | sem histórias |
| [EP-008 · Inimigos, IA e facções](epicos/EP-008-inimigos-ia-e-faccoes.md) | backlog | must | M1 | sem histórias |
| [EP-009 · Morte, derrubado e saque](epicos/EP-009-morte-derrubado-e-saque.md) | backlog | must | M1 | sem histórias |
| [EP-010 · Dungeon aleatória solo](epicos/EP-010-dungeon-aleatoria-solo.md) | backlog | must | M1 | sem histórias |
| [EP-011 · HUD, UI e onboarding](epicos/EP-011-hud-ui-e-onboarding.md) | backlog | must | M1 | sem histórias |
| [EP-012 · Conteúdo de grupo (dungeon de teste e acampamentos)](epicos/EP-012-conteudo-de-grupo.md) | backlog | must | M1 | sem histórias |

## Em andamento e em revisão

| História | Status | Épico | Prioridade | Pts |
| --- | --- | --- | --- | --- |
| [US-001 · Configurar toolchain com Rokit e Rojo](historias/US-001-configurar-toolchain-com-rokit-e-rojo.md) | revisao | EP-001 | must | 2 |
| [US-002 · Criar repositório Git e GitHub](historias/US-002-criar-repositorio-git-e-github.md) | revisao | EP-001 | must | 1 |
| [US-003 · Estrutura de pastas e projeto Rojo](historias/US-003-estrutura-de-pastas-e-projeto-rojo.md) | revisao | EP-001 | must | 2 |
| [US-004 · Lint e formatação automáticos](historias/US-004-lint-e-formatacao-automaticos.md) | revisao | EP-001 | should | 2 |
| [US-006 · Preparar o repositório para o Claude Code](historias/US-006-preparar-o-repositorio-para-o-claude-code.md) | revisao | EP-001 | should | 1 |

## Prontas para começar

_Nada por aqui._

## Backlog

| História | Status | Épico | Prioridade | Pts |
| --- | --- | --- | --- | --- |
| [US-005 · Comunicação cliente-servidor de exemplo](historias/US-005-comunicacao-cliente-servidor-de-exemplo.md) | backlog | EP-001 | must | 3 |
| [US-007 · Loader de Services e Controllers](historias/US-007-loader-de-services-e-controllers.md) | backlog | EP-001 | must | 2 |
| [US-008 · Config tipado do protótipo](historias/US-008-config-tipado-do-prototipo.md) | backlog | EP-001 | must | 1 |
| [US-009 · Câmera em shift-lock com trava de alvo e boneco de treino](historias/US-009-camera-shift-lock-trava-de-alvo-e-boneco.md) | backlog | EP-001 | must | 5 |
| [US-010 · Corrida e pulo pedidos ao servidor](historias/US-010-corrida-e-pulo.md) | backlog | EP-001 | must | 2 |
| [US-011 · Validação de movimento no servidor](historias/US-011-validacao-de-movimento-no-servidor.md) | backlog | EP-001 | must | 3 |
| [US-012 · Três habilidades com energia e cooldown contra o boneco](historias/US-012-tres-habilidades-com-energia-e-cooldown.md) | backlog | EP-001 | must | 5 |
| [US-013 · Esquiva e parry](historias/US-013-esquiva-e-parry.md) | backlog | EP-001 | must | 5 |
| [US-014 · Spike de desempenho do terreno](historias/US-014-spike-de-desempenho-do-terreno.md) | backlog | EP-001 | must | 3 |

## Concluídas

_Nada por aqui._

## Decisões (ADRs)

| ADR | Status |
| --- | --- |
| [ADR-000 · Registrar decisões com ADRs](../arquitetura/adr/ADR-000-registrar-decisoes-com-adrs.md) | aceito |
| [ADR-001 · Desenvolvimento externo com Rojo e Git](../arquitetura/adr/ADR-001-desenvolvimento-externo-com-rojo-e-git.md) | aceito |
| [ADR-002 · Servidor autoritativo](../arquitetura/adr/ADR-002-servidor-autoritativo.md) | aceito |
| [ADR-003 · Luau em modo strict](../arquitetura/adr/ADR-003-luau-em-modo-strict.md) | aceito |

## Bugs abertos

_Nada por aqui._
