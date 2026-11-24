---
tipo: historia
id: US-038
titulo: Derrubado em vez de morrer, com os tempos de cada zona
status: revisao
prioridade: must
epico: EP-009
pontos: 5
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-038 · Derrubado em vez de morrer, com os tempos de cada zona

## História
**Como** jogador,
**quero** ser derrubado em vez de morrer quando minha vida acaba,
**para que** a punição dependa da zona e eu nunca perca o progresso (Pilar 3).

## Contexto
Aba [Zonas e Risco](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#117aa7d2-031b), tabela do derrubado:
- **Tempo no chão:** 10 s na Azul e na Amarela, 45 s na Vermelha.
- **Ao fim:** levanta com 25% de vida.
- **Monstros:** param de atacar quem está derrubado.
- **Durabilidade:** −5% ao ser derrotado.
- **Zona Preta (M3):** não levanta e morre; o código já trata isso.

Decisões do dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)):
- **Durabilidade:** são 5 pontos em cada peça vestida, inclusive quando um monstro derruba na Vermelha.
- **Reset do Roblox:** fica desligado, para ninguém escapar do derrubado.

## Critérios de aceite
**Cenário 1: derrubado**
- **Dado** um jogador na zona Azul com pouca vida
- **Quando** um bandido acerta o golpe que o mataria
- **Então** ele cai derrubado: não anda nem ataca, a tela mostra "Derrubado · Você levanta em 10 s", e os inimigos o deixam em paz

**Cenário 2: sem dano**
- **Dado** um jogador derrubado
- **Quando** alguém tenta acertá-lo
- **Então** ele não toma dano

**Cenário 3: levantar**
- **Dado** um jogador derrubado na Azul
- **Quando** passam 10 s
- **Então** ele levanta com 25% da vida, e cada peça vestida perde 5 pontos de durabilidade

**Cenário 4: Vermelha**
- **Dado** um jogador derrubado na Vermelha
- **Quando** ele cai
- **Então** fica 45 s no chão

**Cenário 5: sem reset**
- **Dado** um jogador derrubado
- **Quando** ele procura o "Reset" no menu do Roblox
- **Então** a opção está desligada

## Notas técnicas (arquiteto → dev)
- Lado: servidor e cliente
- Módulos afetados: `Services/KnockdownService` (novo), `DefenseService` (golpe fatal vai para o derrubado, sem dano em quem está no chão), `InventoryService.wearDown`, `Config/Zones` (tempos por zona), `Config/Knockdown` (novo), `Shared.Knockdown` (novo), `EnemyService`, `CombatService`, `KnockdownController` (novo)
- Remotes e validação no servidor: nenhum pedido novo nesta história; o servidor publica o derrubado em atributos do jogador
- Dados persistidos: a durabilidade dos itens, pelo inventário do perfil

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):**
- **Golpe fatal:** o `DefenseService` não aplica mais o golpe que zeraria a vida. Ele chama o `KnockdownService`, que deixa a vida em 1, põe o personagem no chão (`PlatformStand`) e publica `DownedUntil`.
- **No chão:** quem está derrubado não toma dano, não usa habilidades ("derrubado") e sai da lista de alvos dos inimigos e dos jogadores.
- **Fim do tempo:** levanta com 25% e perde a durabilidade (`Config/Knockdown`). O conserto vem com a cidade (EP-007).

**Para o Davi testar no Studio:**
1. **Derrubado:** na Azul de teste, deixe os bandidos (60 studs à esquerda) baterem até a vida acabar. Você cai, a tela escurece com a contagem, e os bandidos voltam para casa.
2. **Levantar:** depois de 10 s você levanta com um quarto da vida. No inventário (I), a durabilidade das peças caiu 5 pontos.
3. **Vermelha:** repita na Vermelha (depois de 650 studs): a contagem começa em 45 s.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
