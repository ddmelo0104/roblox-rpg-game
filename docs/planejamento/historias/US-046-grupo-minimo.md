---
tipo: historia
id: US-046
titulo: Grupo mínimo com convite, fama e bolsas divididas
status: revisao
prioridade: must
epico: EP-012
pontos: 5
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-046 · Grupo mínimo com convite, fama e bolsas divididas

## História
**Como** jogador,
**quero** formar um grupo com amigos,
**para que** a gente lute junto, divida a fama e o loot e não se acerte por engano.

## Contexto
Escopo do EP-012: um grupo mínimo (convite e divisão de loot) já no M1; guildas no M3. Aba [Progressão](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#31c067be-9c32): em grupo, cada membro recebe `F × (1 + 0,15 × (n − 1)) / n`. Decisões do dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)):
- **Tamanho:** até 4 jogadores.
- **Convite:** pelo prompt "Convidar para o grupo" (V) no personagem do outro, com 30 s para responder.
- **Divisão:** fama e bolsa valem para os membros a até 80 studs do abate.
- **Sem dano entre membros** do mesmo grupo.

## Critérios de aceite
**Cenário 1: convidar**
- **Dado** dois jogadores sem grupo, perto um do outro
- **Quando** um segura V no outro
- **Então** o outro vê "Fulano te convidou para um grupo" com Aceitar e Recusar, por 30 s

**Cenário 2: aceitar**
- **Dado** um convite recebido
- **Quando** o jogador clica em Aceitar
- **Então** os dois aparecem no painel "Grupo", à esquerda, com a vida de cada um

**Cenário 3: fama em grupo**
- **Dado** dois membros perto de um bandido T1 que um deles derrota
- **Quando** o bandido cai
- **Então** cada um ganha 10 × 1,15 / 2 = 5,75 de fama

**Cenário 4: bolsa do grupo**
- **Dado** um abate de um membro que deixa bolsa
- **Quando** outro membro tenta pegar nos primeiros 20 s
- **Então** consegue, porque a bolsa é do grupo

**Cenário 5: sem dano entre membros**
- **Dado** dois membros na zona Vermelha
- **Quando** um tenta acertar o outro
- **Então** o golpe não acerta, e a trava não pega o colega

**Cenário 6: sair**
- **Dado** um jogador num grupo de 2
- **Quando** ele clica em "Sair do grupo"
- **Então** o grupo acaba, e os dois ficam sozinhos

## Notas técnicas (arquiteto → dev)
- Lado: servidor e cliente
- Módulos afetados: `Services/GroupService` (novo), `Config/Groups` (novo), `EnemyService` (fama em grupo e dono da bolsa), `CombatService` e `KnockdownService` (sem dano nem finalizar entre membros), `GroupController` (novo), `TargetController`, `Config/Progression.GROUP_FAME_BONUS`
- Remotes e validação no servidor: `RequestGroupAnswer(boolean)` e `RequestGroupLeave`; o servidor confere o convite pendente, o prazo e o tamanho do grupo. `GroupUpdate` é aviso do servidor
- Dados persistidos: nenhum: o grupo dura enquanto os jogadores estão no servidor

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):**
- **Convite:** fica num prompt em cada personagem, e o próprio jogador não vê o dele.
- **Atributo `GroupId`:** o servidor o publica em cada jogador, e o cliente usa para a trava não pegar colegas.
- **Abate em grupo:** a parte do dano de todos os membros perto soma e é dividida com o bônus.

**Para o Davi testar no Studio** (Test → Clients and Servers → 2 players):
1. **Convidar:** um jogador chega perto do outro e segura V. O outro clica em Aceitar, e o painel "Grupo" aparece nos dois.
2. **Fama:** derrotem juntos um bandido da Azul. Os dois veem "+5,8 fama".
3. **Sem dano:** na Vermelha, um tenta acertar o outro. Não acerta.
4. **Sair:** clique em "Sair do grupo".

Passando, mude `status` para `concluido` e preencha `concluido_em`.
