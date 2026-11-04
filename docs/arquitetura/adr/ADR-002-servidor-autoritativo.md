---
tipo: adr
id: ADR-002
titulo: Servidor autoritativo
status: aceito
epicos: EP-001
criado: 2026-10-29
decidido_em: 2026-11-04
substitui:
substituido_por:
---

# ADR-002 · Servidor autoritativo

> [!NOTE]
> Status: **aceito** em 04/11/2026 pelo Davi (opção B).

## Contexto
No Roblox, o cliente roda na máquina do jogador e pode ser modificado por exploiters. Num RPG com saque total e mercado entre jogadores, XP, dano, loot e moeda são alvos óbvios de trapaça.

## Opções consideradas
### Opção A: confiar no cliente para os cálculos
- Prós: mais simples, menos latência aparente.
- Contras: qualquer exploiter consegue XP e itens infinitos.

### Opção B: o servidor decide tudo o que importa
- Prós: estado confiável; economia e progressão protegidas.
- Contras: mais código de validação, e é preciso disfarçar a latência no cliente (feedback otimista só visual).

## Decisão
> [!IMPORTANT]
> **Decidido: opção B.** O cliente só envia **intenções** ("quero atacar o alvo X", "quero equipar o item Y"). O servidor valida (tipo, distância, cooldown, posse) e aplica.

## Consequências
- Todo Remote tem validação no servidor, e isso é item obrigatório da Definition of Done.
- Efeitos visuais podem ser previstos no cliente, mas o resultado sempre vem do servidor.
