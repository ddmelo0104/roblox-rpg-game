---
tipo: adr
id: ADR-001
titulo: Desenvolvimento externo com Rojo e Git
status: aceito
epicos: EP-001
criado: 2026-10-29
decidido_em: 2026-11-04
substitui:
substituido_por:
---

# ADR-001 · Desenvolvimento externo com Rojo e Git

> [!NOTE]
> Status: **aceito** em 04/11/2026 pelo Davi (opção B).

## Contexto
Scripts editados só dentro do Roblox Studio não têm Git, revisão de código, lint nem acesso por ferramentas externas como o Claude Code.

## Opções consideradas
### Opção A: só o Roblox Studio
- Prós: zero configuração.
- Contras: sem versionamento real, sem revisão, o Claude não acessa os arquivos.

### Opção B: Rojo + Git + VS Code, com as ferramentas gerenciadas pelo Rokit
- Prós: código em arquivos `.luau`, Git, lint e formatação, integração natural com o Claude Code.
- Contras: setup inicial e curva de aprendizado.

## Decisão
> [!IMPORTANT]
> **Decidido: opção B.** Todo código vive no repositório e é sincronizado com o Studio pelo Rojo.

## Consequências
- O Studio vira ambiente de execução e de construção do mapa; o código-fonte é o repositório.
- Editar scripts dentro do Studio deixa de valer: o Rojo sobrescreve.
- Exige a [US-001](../../planejamento/historias/US-001-configurar-toolchain-com-rokit-e-rojo.md) e a [US-003](../../planejamento/historias/US-003-estrutura-de-pastas-e-projeto-rojo.md).
