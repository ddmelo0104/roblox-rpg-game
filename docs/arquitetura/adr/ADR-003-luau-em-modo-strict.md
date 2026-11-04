---
tipo: adr
id: ADR-003
titulo: Luau em modo strict
status: proposto
epicos: EP-001
criado: 2026-10-29
decidido_em:
substitui:
substituido_por:
---

# ADR-003 · Luau em modo strict

> [!NOTE]
> Status: **proposto**, aguardando a decisão do arquiteto.

## Contexto
O Luau tem um sistema de tipos opcional. Sem tipos, erros como um campo inexistente só aparecem em execução.

## Opções consideradas
- **A: sem tipagem (`--!nonstrict`).** Rápido de escrever, erros descobertos tarde.
- **B: `--!strict` em todo arquivo.** Mais verboso, mas os erros aparecem no editor, e o código gerado pelo Claude fica mais fácil de verificar.

## Decisão
> [!IMPORTANT]
> **Proposta: opção B.** Todo arquivo novo começa com `--!strict`. Exceções são justificadas num comentário.

## Consequências
- Os tipos compartilhados vivem em `src/shared/Types/`.
- O editor precisa da extensão Luau Language Server, que já está nas recomendações do VS Code.
