---
tipo: historia
id: US-036
titulo: PvP na zona Vermelha
status: revisao
prioridade: must
epico: EP-007
pontos: 5
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-036 · PvP na zona Vermelha

## História
**Como** jogador,
**quero** poder lutar contra outros jogadores na zona Vermelha, e só lá,
**para que** o risco e a recompensa maiores venham com o perigo de outros jogadores (Pilar 4).

## Contexto
Aba [Zonas e Risco](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#117aa7d2-031b): no M1, a Amarela não tem PvP e a Vermelha tem PvP livre (a flag chega no M2). A morte, o derrubado e o saque total vêm no EP-009. Decisões do dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)):
- **Trava:** pega outros jogadores só onde os dois podem lutar. É a resposta à pergunta da aba Câmera e Mira.
- **Defesa:** os golpes da espada podem ser aparados; os do arco, da besta e do cajado só a esquiva evita.
- **Atordoado:** um personagem atordoado (parry certo do outro) não usa habilidades nem o ataque básico.

## Critérios de aceite
**Cenário 1: PvP só na Vermelha**
- **Dado** dois jogadores na zona Vermelha, sem proteção de entrada
- **Quando** um ataca o outro
- **Então** o golpe acerta, passando pela esquiva e pelo parry de quem leva

**Cenário 2: fora da Vermelha**
- **Dado** dois jogadores na Amarela ou na Azul
- **Quando** um tenta atacar o outro
- **Então** o golpe não acerta jogadores, e a trava não pega jogadores

**Cenário 3: parry no PvP**
- **Dado** um jogador ataca com a espada outro que apara no tempo certo
- **Quando** o golpe chega
- **Então** é anulado, e o atacante fica 0,5 s atordoado: as habilidades dele dizem "atordoado"

**Cenário 4: à distância**
- **Dado** um jogador atira com o arco
- **Quando** o outro tenta aparar
- **Então** o parry não pega; só a esquiva evita

## Notas técnicas (arquiteto → dev)
- Lado: servidor e cliente
- Módulos afetados: `CombatService` (alvos jogadores pelo `ZoneService.canPvp`, golpe no jogador pelo `DefenseService`, atordoamento), `HIT_KIND` nos Configs das armas, `Shared.Abilities` (motivo "Stunned"), `TargetController`, `CombatController`
- Remotes e validação no servidor: os mesmos pedidos; o servidor confere a zona dos dois e a proteção a cada golpe
- Dados persistidos: nenhum

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):**
- **Alvos:** o `CombatService` junta aos alvos os personagens dos jogadores que o `ZoneService.canPvp` permite. Isso vale nas áreas, no alvo travado, nas áreas no chão e no ataque básico.
- **Golpe em jogador:** passa pelo `DefenseService.receiveHit`, com o tipo da arma (`HIT_KIND`). Isso não conta para o reset do giro.
- **Trava:** o cliente só trava em jogadores onde os dois podem lutar, lendo os atributos de zona e de proteção.
- **Morte:** ainda é a padrão do Roblox. O derrubado, a finalização e o saque total vêm no EP-009.

**Para o Davi testar no Studio** (Test → Clients and Servers → 2 players):
1. **Fora da Vermelha:** os dois na Amarela de teste (400 a 650 studs à esquerda). Os golpes não acertam o outro, e a trava (T) não pega o outro jogador.
2. **Na Vermelha:** os dois vão para a Vermelha (depois de 650 studs) e esperam os 10 s de proteção. Agora a trava pega o outro, e os golpes acertam.
3. **Parry:** um ataca com a espada, e o outro apara (botão direito) no tempo certo: o atacante vê "atordoado" ao tentar uma habilidade logo em seguida.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
