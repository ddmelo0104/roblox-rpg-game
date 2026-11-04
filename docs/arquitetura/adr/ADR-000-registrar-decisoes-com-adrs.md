---
tipo: adr
id: ADR-000
titulo: Registrar decisões com ADRs
status: aceito
criado: 2026-10-29
decidido_em: 2026-10-29
substitui:
substituido_por:
---

# ADR-000 · Registrar decisões com ADRs

## Contexto
O projeto terá muitas decisões técnicas e de design. Sem registro, a gente esquece *por que* algo foi feito e volta a discutir.

## Decisão
> [!IMPORTANT]
> **Toda decisão difícil de reverter vira um ADR.** Usamos *Architecture Decision Records* curtos (contexto → opções → decisão → consequências) em `docs/arquitetura/adr/`, numerados e imutáveis: para mudar uma decisão, cria-se um novo ADR que **substitui** o anterior.

## Consequências
- O histórico do raciocínio fica preservado, e o Claude pode ler os ADRs como contexto.
- Custo pequeno de escrita a cada decisão. A skill `novo-adr` ajuda a criar.
