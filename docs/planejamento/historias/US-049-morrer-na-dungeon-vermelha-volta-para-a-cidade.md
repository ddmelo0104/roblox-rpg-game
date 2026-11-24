---
tipo: historia
id: US-049
titulo: Morrer numa dungeon da Zona Vermelha leva para a cidade
status: revisao
prioridade: must
epico: EP-009
pontos: 1
sprint:
criado: 2026-11-24
atualizado: 2026-11-24
concluido_em:
---

# US-049 · Morrer numa dungeon da Zona Vermelha leva para a cidade

## História
**Como** jogador que morreu numa dungeon da Zona Vermelha,
**quero** voltar para a cidade,
**para que** a morte numa dungeon de risco tenha peso e eu não renasça na porta da sala onde caí.

## Contexto
Pedido do Davi em 23/11: "se o personagem morrer [na] dungeon vermelha ele volta para a cidade".

Antes, quem desistia derrubado voltava ao ponto de retorno da própria zona. Dentro de uma dungeon, esse ponto é o início da dungeon (US-039 e US-041).

Na Vermelha, o derrubado por monstro levanta sozinho depois de 45 s (aba [Zonas e Risco](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#117aa7d2-031b)). Nesse modo, "morrer" é desistir ou ser finalizado:
- **Finalizado por outro jogador:** já ia para a cidade, com saque total (US-040).
- **Desistir:** esta história faz a desistência dentro de uma dungeon da Vermelha também ir para a cidade.

A regra vale para toda dungeon de zona de risco (Vermelha e Preta). Nas outras zonas, desistir continua voltando ao início da dungeon.

## Critérios de aceite
**Cenário 1: desistir na dungeon da Vermelha**
- **Dado** um jogador derrubado por um monstro numa dungeon da Zona Vermelha
- **Quando** ele aperta "Desistir"
- **Então** volta na cidade mais próxima, e não no início da dungeon

**Cenário 2: aviso na tela**
- **Dado** um jogador derrubado numa dungeon da Zona Vermelha
- **Quando** a tela de derrubado aparece
- **Então** ela avisa: "Desistir numa dungeon da Zona Vermelha te leva de volta para a cidade."

**Cenário 3: outras zonas iguais**
- **Dado** um jogador derrubado numa dungeon da Zona Amarela
- **Quando** ele desiste
- **Então** volta no início da dungeon, como antes

**Cenário 4: finalizado**
- **Dado** um jogador derrubado por outro jogador numa dungeon da Zona Vermelha
- **Quando** é finalizado ou desiste
- **Então** perde o que carrega (saque total) e volta na cidade, como antes

## Notas técnicas (arquiteto → dev)
- Lado: servidor e cliente
- Módulos afetados: `Services/KnockdownService` (`inRiskDungeon`, `nearestCity`), `Shared/Knockdown` (atributo `GiveUpToCity`) e `KnockdownController` (aviso)
- Remotes e validação no servidor: nenhum novo; quem decide para onde o jogador volta é o servidor
- Dados persistidos: nenhum

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima)
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-24):**
- **Regra:** quando um jogador desiste, o servidor olha a zona em que ele caiu. Se é uma dungeon (região com o atributo `Dungeon`) de zona de risco, ele volta no ponto de retorno da cidade mais próxima.
- **Aviso:** o atributo `GiveUpToCity` faz a tela de derrubado mostrar o aviso enquanto o jogador está no chão.

**Para o Davi testar no Studio:**
1. **Vermelha:** a entrada de teste da dungeon fica 800 studs à esquerda do spawn e 80 à frente, nos Picos de Stardawn (use o mapa, M). Entre e deixe os bandidos te derrubarem. A tela mostra o aviso da cidade. Aperte "Desistir": você volta em Stardawn.
2. **Amarela:** faça o mesmo na entrada das Colinas (525 studs à esquerda). Desistir volta no início da dungeon.
3. **Finalizado (2 jogadores):** em Test → Clients and Servers, derrube o outro jogador na dungeon da Vermelha e finalize (H). Ele perde o que carrega e volta na cidade.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
