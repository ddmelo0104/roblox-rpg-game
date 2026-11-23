---
tipo: historia
id: US-013
titulo: Esquiva e parry
status: revisao
prioridade: must
epico: EP-001
pontos: 5
sprint:
criado: 2026-11-05
atualizado: 2026-11-23
concluido_em:
---

# US-013 · Esquiva e parry

## História
**Como** jogador,
**quero** esquivar e aparar golpes no tempo certo,
**para que** a minha habilidade decida a luta.

## Contexto
Aba [Combate e Habilidades](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f0d54cbd-810d): a esquiva vem das botas e existe o parry (decisões do Davi, 04/11). Ficam abertas na aba: em quais armas há parry, o que ele apara e qual a recompensa. A Visão diz que o jogo não é "combate baseado em parry": ele é uma ferramenta entre várias. No protótipo há uma esquiva só, até as botas existirem.

## Critérios de aceite
**Cenário 1: esquiva**
- **Dado** um golpe vindo na direção do jogador
- **Quando** ele esquiva a tempo
- **Então** fica invulnerável por um instante, e a esquiva entra em cooldown

**Cenário 2: parry certo**
- **Dado** um golpe corpo a corpo vindo
- **Quando** o jogador faz o parry dentro da janela
- **Então** o golpe é anulado e aparece um sinal forte

**Cenário 3: parry errado**
- **Dado** um parry fora da janela
- **Quando** o golpe chega
- **Então** o jogador fica vulnerável (proposta da aba contra parry automático)

## Notas técnicas (arquiteto → dev)
- Lado: cliente e servidor
- Módulos afetados: `src/server/Services/DefenseService.luau`, `src/server/SparringDummy.luau`, `src/server/Services/TrainingDummyService.luau`, `src/client/Controllers/DefenseController.luau`, `src/client/Controllers/CombatHudController.luau`, `src/client/Notices.luau`, `src/shared/Defense.luau`, `src/shared/Config/Combat.luau` e `Training.luau`
- Remotes e validação no servidor: intenções de esquiva e de parry, com o tempo conferido no servidor dentro da margem de lag (ADR-009)
- Dados persistidos: nenhum
- ADRs relevantes: [ADR-009](../../arquitetura/adr/ADR-009-acerto-das-habilidades-no-servidor-com-margem-de-lag.md) (proposto), [ADR-010](../../arquitetura/adr/ADR-010-validacao-de-movimento-no-servidor.md) (proposto), [ADR-002](../../arquitetura/adr/ADR-002-servidor-autoritativo.md)

## Tarefas
- [x] Esquiva com invulnerabilidade curta e cooldown
- [x] Parry com janela e punição por erro
- [x] Um golpe do boneco de treino para treinar o tempo
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):** o Davi pediu em 23/11 para seguir com tudo o que fosse possível.
- **Esquiva (F):**
  - Um avanço de 12 studs em 0,25 s, na direção em que o personagem anda; parado, um passo para trás.
  - Dá 0,35 s de invulnerabilidade e tem 2 s de cooldown. Não gasta energia: sem energia, sobra a defesa (aba Combate).
  - O cliente avança na hora, porque roda a física do personagem, e pede a invulnerabilidade ao servidor. A validação de movimento (US-011) aceita esse avanço.
- **Parry (botão direito do mouse):**
  - Abre uma janela de 0,3 s. Um golpe corpo a corpo que chega nela é anulado.
  - O sinal forte é um "APAROU!" grande em cima do personagem e um clarão na tela de quem aparou.
  - Um parry que não pega nenhum golpe deixa o jogador vulnerável por 1 s: sem esquiva e sem parry, com a borda dos quadros vermelha no HUD.
- **Empate com o lag:** a defesa vale se começou até 0,1 s depois do golpe (`DEFENSE_GRACE`), porque a aba propõe que ganhe quem defende.
- **Boneco que ataca:**
  - Um quarto boneco, no fim da fileira (14 studs depois do último), golpeia o jogador mais perto a até 8 studs.
  - Antes do golpe, ele vira para o jogador, e o tronco fica vermelho por 0,8 s. O golpe tira 15 de vida, e há 2,5 s entre um golpe e outro.
  - Ele também pode ser travado e atingido pelas habilidades.
- **HUD:** dois quadros novos, F (Esquiva) e M2 (Aparar), com o cooldown. Os textos "Esquivou", "APAROU!" e "Errou o tempo" e o dano sobem do personagem.
- **Rede:** Remotes `RequestDodge`, `RequestParry`, `DefenseState` e `DefenseEvent`. Os avisos ao jogador agora ficam em `src/client/Notices.luau`, usado pelas habilidades e pela defesa.

**Interpretações do dev, para o Davi confirmar:**
- **"Fica vulnerável" depois de errar o parry:** 1 s sem esquiva e sem parry. O dano recebido não aumenta.
- **Direção da esquiva:** para onde o personagem anda; parado, para trás.
- **Custo:** esquiva e parry não gastam energia.
- **O que o parry pega:** só golpe corpo a corpo. Projéteis e magias ainda são pergunta aberta da aba.

**Decisão de game design pendente:** a recompensa do parry certo, que é pergunta aberta da aba. Hoje ele só anula o golpe. As opções da aba são atordoar o atacante, devolver energia ou abrir para um golpe forte.

**Limitações conhecidas:**
- **Esquiva prevista no cliente:** num caso raro de lag, a validação de movimento pode puxar o personagem antes de o pedido de esquiva chegar ao servidor.
- **Golpe visto com atraso:** o jogador vê o golpe do boneco com o atraso da rede. Com ping alto, acertar o tempo do parry fica mais difícil, e a margem de 0,1 s ajuda só um pouco.
- **Visual provisório:** não há animação nem som, e o boneco é um placeholder.

**Para o Davi testar no Studio:**
1. **Preparação:** dê Play. Além dos 3 bonecos, aparece o "Boneco que ataca" no fim da fileira. O HUD tem 5 quadros: Q, E, R, F e M2.
2. **Cenário 1 (esquiva):**
   - Chegue perto do boneco que ataca. Quando o tronco dele ficar vermelho, ande para o lado e aperte F. O personagem avança, e "Esquivou" aparece em cima dele, sem dano.
   - Aperte F de novo logo depois: o aviso "Esquiva: em recarga" aparece.
3. **Cenário 2 (parry certo):** quando o tronco ficar vermelho, espere quase o fim (ele dura 0,8 s) e aperte o botão direito do mouse. "APAROU!" aparece, a tela pisca e não há dano.
4. **Cenário 3 (parry errado):** aperte o botão direito longe do boneco, ou cedo demais. "Errou o tempo" aparece, e os quadros F e M2 ficam com a borda vermelha por 1 s. Nesse tempo, F e M2 avisam "vulnerável".
5. **Sem defesa:** fique parado perto do boneco. O golpe tira 15 de vida a cada 2,5 s, e o número vermelho sobe.
6. **Pedido repetido:** na barra de comandos do cliente, rode `game.ReplicatedStorage.Remotes.RequestParry:FireServer()` duas vezes seguidas. A segunda é recusada ("em recarga"), sem erro.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
