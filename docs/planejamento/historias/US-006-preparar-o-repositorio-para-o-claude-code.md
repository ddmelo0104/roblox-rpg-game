---
tipo: historia
id: US-006
titulo: Preparar o repositório para o Claude Code
status: revisao
prioridade: should
epico: EP-001
pontos: 1
sprint:
criado: 2026-10-29
atualizado: 2026-11-04
concluido_em:
---

# US-006 · Preparar o repositório para o Claude Code

## História
**Como** arquiteto que trabalha com o Claude como dev,
**quero** um `CLAUDE.md` na raiz do repositório resumindo arquitetura, convenções e onde ficam as histórias,
**para que** o Claude Code tenha o mesmo contexto que o planejamento.

## Critérios de aceite
**Cenário 1: contexto sem explicação**
- **Dado** o Claude Code aberto no repositório
- **Quando** eu pedir "implemente a US-005"
- **Então** ele encontra a história, as convenções e a estrutura sem eu explicar, e lista dúvidas antes de codar

## Notas técnicas
- Ver [COMO-TRABALHAR-COM-O-CLAUDE.md](../../processo/COMO-TRABALHAR-COM-O-CLAUDE.md).

## Tarefas
- [x] `CLAUDE.md` com papéis, mapa da documentação, regras, fluxo e comandos
- [x] Skills do projeto em `.claude/skills/`: `implementar-historia`, `nova-historia` e `novo-adr`
- [x] Templates em `docs/templates/` e o gerador `tools/backlog.py`
- [ ] Testar com o Claude Code (cenário acima)

## Revisão / resultado
**Feito pelo dev (2026-11-04):** o `CLAUDE.md` aponta para o doc de design no Claude Docs e para a documentação de engenharia em `docs/`. As skills seguem o fluxo das [Definições de Pronto](../DEFINICOES-DE-PRONTO.md). O `BACKLOG.md` é gerado a partir das propriedades de cada arquivo, e o CI confere se ele está em dia.

**Para o Davi testar:** abra o repositório no Claude Code e peça "implemente a US-005" (ou rode `/implementar-historia US-005`). Ele deve apontar que a história ainda está em `backlog` e perguntar antes de começar.
