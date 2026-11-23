---
tipo: adr
id: ADR-007
titulo: Instâncias de dungeon no mesmo servidor da zona
status: proposto
epicos: EP-010
criado: 2026-11-23
decidido_em:
substitui:
substituido_por:
---

# ADR-007 · Instâncias de dungeon no mesmo servidor da zona

> [!NOTE]
> Status: **proposto** → aceito → (obsoleto | substituído).

## Contexto
A dungeon aleatória solo do M1 é gerada por semente e tem uma instância por entrada (aba Dungeons). É preciso decidir onde a instância roda: no servidor da zona, numa área isolada do mapa, ou num *reserved server* próprio, via TeleportService. A aba Dungeons já trazia a proposta técnica A no M1.

## Opções consideradas
### Opção A: no mesmo servidor, numa área isolada
- Prós:
  - Sem tela de carregamento nem troca de servidor; entrar e sair é um teleporte dentro do place.
  - O estado (inventário, perfil, combate, bolsas) fica num servidor só, sem risco de duplicação entre servidores.
  - Testa no Studio com um Play.
- Contras:
  - As instâncias dividem o orçamento do servidor da zona (partes, inimigos, física).
  - Muitas dungeons abertas ao mesmo tempo pesam no servidor.

### Opção B: um *reserved server* por instância
- Prós: cada dungeon tem um servidor só para ela, e o servidor da zona fica leve.
- Contras:
  - Teleporte com carregamento.
  - O perfil é salvo e solto a cada entrada e saída (ADR-005), com mais pontos de falha.
  - Só testa com o jogo publicado.

## Decisão
> [!IMPORTANT]
> **Proposta: opção A no M1.** As instâncias são construídas longe do mundo (`Config/Dungeons.INSTANCE_ORIGIN`), uma ao lado da outra, e removidas quando ficam vazias e a entrada fechou.
> **O gerador fica isolado** (`Shared.DungeonLayout`, uma função pura da semente) e o construtor também (`DungeonBuilder`). Passar para a opção B depois muda só onde a instância é construída.

## Consequências
- **Positivas:**
  - Dungeon jogável já no M1, sem infraestrutura de teleporte.
  - A mesma semente gera a mesma dungeon (bom para reproduzir bugs).
- **Negativas e trade-offs aceitos:**
  - O servidor da zona carrega as instâncias abertas.
  - Os inimigos delas dormem enquanto não há jogador por perto, como no mundo aberto.
- **O que passa a ser obrigatório:**
  - A instância tem uma região de zona com o tipo e o tier da entrada, para as regras da zona valerem lá dentro.
  - Todo teleporte de entrada e saída passa pela validação de movimento e avisa o `ZoneService`.

## Referências
- Aba Dungeons do doc de design (proposta técnica e casos-limite).
- [ADR-004](ADR-004-um-place-so-no-m1.md): um place só no M1.
