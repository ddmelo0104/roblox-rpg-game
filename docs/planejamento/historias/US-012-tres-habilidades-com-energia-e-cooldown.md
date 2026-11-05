---
tipo: historia
id: US-012
titulo: Três habilidades com energia e cooldown contra o boneco
status: revisao
prioridade: must
epico: EP-001
pontos: 5
sprint:
criado: 2026-11-05
atualizado: 2026-11-05
concluido_em:
---

# US-012 · Três habilidades com energia e cooldown contra o boneco

## História
**Como** jogador,
**quero** usar 3 habilidades de uma arma, gastando energia e respeitando o cooldown, contra o boneco de treino,
**para que** eu sinta o combate e o Davi ajuste os números.

## Contexto
Aba [Combate e Habilidades](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f0d54cbd-810d): energia e cooldown em toda habilidade, e os tipos no alvo, em direção, em área e em volta de si. As habilidades de área acertam todos os inimigos dentro delas (decisão do Davi, 04/11). O protótipo usa uma arma só (risco do EP-001). O acerto segue o [ADR-009](../../arquitetura/adr/ADR-009-acerto-das-habilidades-no-servidor-com-margem-de-lag.md) (proposto).

**Arma e habilidades, definidas pelo Davi em 05/11:** a espada longa.
1. **Corte frontal:** 1,5 m para a frente, com largura para acertar 3 inimigos à frente.
2. **Golpe no alvo:** dano num alvo só, o inimigo travado, com mais dano.
3. **Giro:** ataque giratório. O cooldown zera se um inimigo for derrubado.

## Critérios de aceite
**Cenário 1: corte frontal**
- **Dado** 3 bonecos lado a lado, à frente do jogador e a até 1,5 m
- **Quando** ele usa o corte frontal virado para eles
- **Então** o servidor aplica o dano nos 3, e nada atrás do jogador ou fora da área é atingido

**Cenário 2: golpe no alvo**
- **Dado** um boneco travado e dentro do alcance
- **Quando** o jogador usa o golpe no alvo
- **Então** só esse boneco perde vida, e mais do que com as outras habilidades
- **E** sem alvo travado o golpe não sai, e o HUD avisa

**Cenário 3: giro**
- **Dado** bonecos em volta do jogador
- **Quando** ele usa o giro
- **Então** todos os que estão dentro do raio perdem vida
- **E** se o giro derrubar algum, o cooldown do giro zera na hora

**Cenário 4: sem energia ou em cooldown**
- **Dado** o jogador sem energia, ou a habilidade em cooldown
- **Quando** ele tenta usar
- **Então** o servidor recusa e nada acontece

**Cenário 5: fora de alcance ou sem visão**
- **Dado** o boneco travado fora do alcance ou atrás de uma parede
- **Quando** o jogador usa o golpe no alvo
- **Então** o servidor recusa

**Cenário 6: feedback**
- **Dado** o jogador em combate
- **Quando** ele usa as habilidades
- **Então** vê a barra de energia, o cooldown de cada uma, o dano em cima dos bonecos e o motivo de cada recusa

## Notas técnicas (arquiteto → dev)
- Lado: cliente e servidor
- Módulos afetados:
  - Config: `src/shared/Config/Longsword.luau` (as 3 habilidades), `src/shared/Config/Combat.luau` (energia e margem de lag) e `src/shared/Config/Training.luau` (3 bonecos)
  - Shared: `src/shared/Abilities.luau` (tipos e contas da área), `src/shared/Energy.luau` e `src/shared/Targets.luau`
  - Servidor: `src/server/Services/CombatService.luau` e `src/server/Services/EnergyService.luau`
  - Cliente: `src/client/Controllers/CombatController.luau`, `CombatEffectsController.luau` e `CombatHudController.luau`
- Remotes e validação no servidor:
  - `RequestAbility`: o cliente manda o id, a direção no plano e, no golpe, o alvo travado. O servidor responde a quem pediu com a hora em que a habilidade fica pronta e, se recusou, o motivo.
  - `AbilityUsed`: o servidor avisa todos de quem usou, qual habilidade, de onde, quem foi atingido e o dano.
  - `Network.onReceive` confere o tipo do id, o vetor (sem NaN) e a instância. Depois, o `CombatService` confere cooldown, alvo, alcance, linha de visão e energia.
- Dados persistidos: nenhum
- ADRs relevantes: [ADR-009](../../arquitetura/adr/ADR-009-acerto-das-habilidades-no-servidor-com-margem-de-lag.md) (proposto) e [ADR-002](../../arquitetura/adr/ADR-002-servidor-autoritativo.md)

## Tarefas
- [x] Escrever o ADR-009 (proposto em 05/11); falta o aceite do Davi
- [x] Definir com o Davi a arma e as 3 habilidades do protótipo (05/11)
- [x] Energia e cooldown no servidor, dano no boneco
- [x] HUD mínimo de energia e cooldown
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-05):** o Davi pediu em 05/11 para construir a história junto com os ADR-009 e ADR-010.
- **`Config/Longsword`:** as 3 habilidades, com as distâncias escritas em metros (no Roblox, 1 stud = 0,28 m).
- **`Config/Combat`:** energia máxima, regeneração, a margem de lag do ADR-009 e a diferença de altura aceita.
- **`Shared.Abilities`:** os tipos e as contas da área (à frente e em volta). O cliente e o servidor usam as mesmas contas. Ao iniciar, o servidor confere o Config e para com uma mensagem clara se um campo estiver errado.
- **`EnergyService`:** a energia mora no servidor e vai para atributos do jogador, que o HUD lê.
- **`CombatService`:** confere cooldown, alvo, alcance, linha de visão e energia, aplica o dano, zera o cooldown do giro quando ele derruba alguém e avisa todos os clientes.
- **`CombatController`:**
  - Ouve Q, E e R e confere antes de pedir: cooldown, energia, alvo travado e alcance.
  - Desenha o efeito e conta o cooldown na hora.
  - Desfaz o efeito se o servidor recusar.
- **`CombatEffectsController`:** desenha a área ou a linha do golpe, e o número de dano em cima de quem foi atingido.
- **`CombatHudController`:** barra de energia, um quadro por habilidade com o cooldown, borda vermelha quando falta energia, e o último aviso.
- **`TrainingDummyService`:** agora cria 3 bonecos lado a lado, a 4 studs de distância entre os centros (`Config/Training`).
- **`TargetController`:** passa o alvo travado para as habilidades e usa `Shared.Targets` na lista de candidatos e na linha de visão.

**Valores provisórios** (ajuste em `Config/Longsword` e `Config/Combat`):

| Habilidade | Tecla | Área | Energia | Cooldown | Dano |
| --- | --- | --- | --- | --- | --- |
| Corte frontal | Q | 1,5 m à frente × 2,25 m de largura (≈ 5,4 × 8 studs) | 10 | 2 s | 100 |
| Golpe no alvo | E | alvo travado a até 1,5 m | 20 | 6 s | 220 |
| Giro | R | raio de 1,5 m em volta de si | 25 | 8 s | 80 |

A energia vai até 100 e volta 5 por segundo. A margem de lag é de 1,5 stud, e a diferença de altura aceita é de 5 studs.

**Interpretações do dev, para o Davi confirmar:**
- **Largura do corte:** cabem 3 inimigos lado a lado. A área acerta todos os que estão dentro dela, sem limite de 3, como as outras áreas (decisão de 04/11).
- **Golpe no alvo:** exige alvo travado e usa o alcance da espada (1,5 m).
- **Giro:** o cooldown zera quando o próprio giro derruba um inimigo, não com qualquer abate, e a energia gasta não volta. O raio é o alcance da espada (1,5 m).
- **Quem leva dano:** só alvos com a tag (os bonecos e, depois, os inimigos). Jogadores não, porque o PvP depende das regras de zona.
- **Energia ao renascer:** a energia enche a cada personagem novo.
- **Direção:** com alvo travado, o corte sai na direção do alvo; sem trava, para onde o personagem olha.

**Limitações conhecidas:**
- **Sem animação nem som.** O corte é uma placa, o giro é um disco e o golpe é uma linha, em neon, e somem em 0,35 s.
- **Efeito para os outros:** quem usa vê o efeito na hora. Os outros jogadores só veem quando o servidor avisa.
- **Fora do escopo:** não há ataque básico, e ninguém fica parado durante a habilidade (perguntas abertas da aba).
- **Provisórios:** o HUD (a UI de verdade é do EP-011) e as teclas Q, E e R.

**Para o Davi testar no Studio:**
1. **Início:** dê Play. No Output devem aparecer:
   - `services: CombatService, EnergyService, MovementService, PingService, TrainingDummyService`
   - `controllers: CameraController, CombatController, CombatEffectsController, CombatHudController, MovementController, PingController, TargetController`

   Três bonecos aparecem lado a lado à frente do spawn. Embaixo da tela ficam a barra de energia (100 / 100) e os quadros Q, E e R.
2. **Cenário 1:** fique a uns 4 studs do boneco do meio, virado para ele, e aperte Q. Uma placa amarela aparece à frente, e "100" sobe dos 3 bonecos. Depois vire de costas para eles e aperte Q: nenhum número aparece.
3. **Cenário 2:**
   - Sem trava, aperte E. O aviso "Golpe no alvo: trave um inimigo primeiro" aparece acima dos quadros.
   - Trave um boneco (T), chegue perto e aperte E. Uma linha vermelha vai até ele, e "220" sobe só dele.
4. **Cenário 3:**
   - Fique encostado no boneco do meio e aperte R. Um disco azul aparece, e "80" sobe de todos os bonecos dentro do raio. O quadro R escurece por 8 s.
   - Para ver o cooldown zerar, rode na barra de comandos do servidor: `for _, dummy in workspace:GetChildren() do if dummy.Name == "TrainingDummy" then dummy.Humanoid.Health = 50 end end`.
   - Espere o R voltar e aperte R. Os bonecos caem, o quadro R não escurece, e dá para usar R de novo na hora.
5. **Cenário 4:**
   - Aperte Q duas vezes seguidas. O aviso "Corte frontal: em recarga" aparece.
   - Use Q, E e R sem parar até a energia acabar (uns 15 s). O aviso "…: sem energia" aparece, e a borda dos quadros fica vermelha.
6. **Cenário 5:**
   - Trave um boneco, afaste-se uns 8 studs e aperte E. O aviso "Golpe no alvo: fora de alcance" aparece.
   - Para ver o servidor recusar, ponha uma parede entre você e o boneco travado e aperte E em menos de 1,5 s, antes de a trava soltar. O aviso "Golpe no alvo: sem linha de visão" aparece.
7. **Pedido inválido:** na barra de comandos do cliente, rode `game.ReplicatedStorage.Remotes.RequestAbility:FireServer("BolaDeFogo", Vector3.new(0, 0, -1))`. O servidor avisa `[Network] RequestAbility rejected from …: unknown option`, sem erro.
8. **Com 2 jogadores** (Test → Clients and Servers → 2 players): o jogador 2 vê o efeito e os números de dano quando o jogador 1 usa as habilidades.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
