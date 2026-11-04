---
name: novo-adr
description: Registra uma decisão técnica como ADR (Architecture Decision Record) com o próximo número livre, a partir do template. Use quando surgir uma decisão difícil de reverter ou quando o Davi pedir para registrar uma decisão.
argument-hint: decisão a registrar
---

# Registrar um ADR

1. **Próximo número:** o maior `ADR-NNN` em `docs/arquitetura/adr/` mais 1.
2. **Crie o arquivo:** copie `docs/templates/adr.md` para `docs/arquitetura/adr/ADR-NNN-titulo-em-kebab-case.md` (sem acentos no nome).
3. **Preencha** o contexto, pelo menos duas opções com prós e contras, a decisão proposta e as consequências. O que for fato técnico do Roblox, confira na documentação oficial e cite em "Referências".
4. **Deixe `status: proposto`.** Quem aceita é o Davi.
5. **Se ele substitui outro ADR,** preencha `substitui` no novo e `substituido_por` no antigo. O antigo nunca é apagado.
6. **Rode `python3 tools/backlog.py`.**
