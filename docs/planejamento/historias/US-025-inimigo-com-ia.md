---
tipo: historia
id: US-025
titulo: Inimigo com IA que percebe, persegue, ataca e volta
status: revisao
prioridade: must
epico: EP-008
pontos: 5
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-025 · Inimigo com IA que percebe, persegue, ataca e volta

## História
**Como** jogador,
**quero** inimigos que me percebam, me persigam e ataquem com um aviso que dá para ler,
**para que** a luta tenha ameaça e a esquiva e o parry façam diferença.

## Contexto
Escopo do EP-008: IA que percebe, persegue, ataca e volta; o inimigo que não alcança o jogador reseta e não dá fama (aba [Progressão](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#31c067be-9c32), casos-limite); inimigos dormem sem jogador por perto. História criada pelo dev por delegação (23/11). Os números são provisórios e estão no [registro de decisões delegadas](../DECISOES-DELEGADAS.md):
- percebe a 30 studs (o arqueiro, a 40), com linha de visão;
- desiste quando o alvo passa de 60 studs da casa dele (coleira) ou quando tenta andar e fica 4 s sem sair do lugar (preso);
- volta para casa sem poder ser atacado, cura tudo e esquece o dano que levou;
- dorme sem jogador vivo a 150 studs.

## Critérios de aceite
**Cenário 1: perceber e perseguir**
- **Dado** um bandido parado no lugar dele
- **Quando** o jogador chega a menos de 30 studs, à vista
- **Então** o bandido vai atrás dele

**Cenário 2: ataque com aviso**
- **Dado** o bandido ao alcance do jogador
- **Quando** ele ataca
- **Então** o tronco dele fica vermelho antes do golpe; a esquiva evita o golpe, e o parry certo anula e atordoa o bandido por 0,5 s

**Cenário 3: provocado de longe**
- **Dado** um inimigo parado
- **Quando** um jogador o acerta de fora da distância de percepção
- **Então** o inimigo persegue quem o acertou

**Cenário 4: coleira**
- **Dado** o bandido perseguindo o jogador
- **Quando** o jogador se afasta mais de 60 studs da casa do bandido
- **Então** o bandido desiste, volta para casa (sem poder ser atacado) e recupera toda a vida

**Cenário 5: preso no terreno**
- **Dado** um inimigo que não consegue chegar perto do jogador (preso atrás de um obstáculo)
- **Quando** ele fica 4 s sem conseguir sair do lugar
- **Então** ele reseta: volta, cura e esquece o dano, que não conta para o abate

**Cenário 6: mais rápido não reseta**
- **Dado** um jogador correndo, mais rápido que o inimigo
- **Quando** o inimigo o persegue
- **Então** ele não reseta enquanto consegue andar; só a coleira o faz desistir

**Cenário 7: dormir**
- **Dado** nenhum jogador vivo a menos de 150 studs
- **Quando** o servidor roda a IA
- **Então** o inimigo dorme (só é conferido uma vez por segundo) e acorda quando alguém chega

## Notas técnicas (arquiteto → dev)
- Lado: servidor (o cliente só solta a trava de um inimigo que voltou a ser "não alvo")
- Módulos afetados: `src/server/EnemyBrain.luau` (a IA), `src/server/EnemyBody.luau` (o corpo provisório), `Services/EnemyService` (o laço da IA), `Services/DamageService`, `src/shared/Config/Enemies.luau`, `Shared.Enemies`, `TargetController`, `PerformanceController`
- Remotes e validação no servidor: nenhum Remote novo. O servidor é dono da física do inimigo (`SetNetworkOwner(nil)`), e os golpes passam pelo `DefenseService.receiveHit`, como os do boneco que ataca
- Dados persistidos: nenhum

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):**
- **IA no servidor:** um laço só pensa por todos os inimigos (5 decisões por segundo para os acordados) e espalha as decisões entre os quadros. Os estados são parado, perseguindo, atacando, voltando e morto.
- **Ataque:** o aviso dura `windup` (0,7 s no bandido). O golpe só acerta se o jogador ainda estiver ao alcance, com a margem de lag (ADR-009).
- **Preso:** o inimigo reseta quando tenta andar e se move menos de 2 studs em 4 s. Um jogador apenas mais rápido não o faz resetar (kitar é jogo legítimo); quem limita a perseguição é a coleira.
- **Voltando para casa:** o inimigo perde a tag de alvo, e a trava do cliente o solta. Em casa, cura tudo e esquece quem o feriu.
- **Painel F3:** mostra quantos inimigos estão acordados e quanto tempo de servidor a IA gasta por segundo. Para medir o custo de uma zona cheia, `Config/Debug.EXTRA_TEST_ENEMIES` cria inimigos dormindo a 400 studs do spawn.
- **Bonecos de treino:** o serviço deles agora confere no `Init` se o place já tem alvos, porque os inimigos também são alvos e nascem antes.

**Limite conhecido:** sem *pathfinding*, um jogador num lugar inalcançável ainda pode bater no inimigo durante os 4 s antes do reset. Como ele cura tudo ao resetar, só um dano muito alto mata nesse tempo. O *pathfinding* entra quando o terreno de Stardawn existir (EP-007).

**Para o Davi testar no Studio:**
1. **Perseguir e atacar:** dê Play e ande para a esquerda do spawn até os 2 bandidos (60 studs). Eles vêm atrás. Antes de cada golpe o tronco fica vermelho; teste a esquiva (F) e o parry (botão direito).
2. **Coleira:** corra de volta para o spawn. Os bandidos desistem, voltam e recuperam a vida.
3. **Provocar de longe:** com um arco, acerte um bandido de uns 35 studs. Ele vem até você.
4. **Dormir:** aperte F3 e afaste-se mais de 150 studs. "Enemies x/y awake" cai para 0 acordados.
5. **Custo da IA:** com `EXTRA_TEST_ENEMIES = 200` no `Config/Debug`, anote o "AI … ms/s" no spawn e perto da fileira de inimigos (400 studs à frente).

Passando, mude `status` para `concluido` e preencha `concluido_em`.
