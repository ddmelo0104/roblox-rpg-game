---
tipo: historia
id: US-009
titulo: Câmera em shift-lock com trava de alvo e boneco de treino
status: revisao
prioridade: must
epico: EP-001
pontos: 5
sprint:
criado: 2026-11-05
atualizado: 2026-11-05
concluido_em:
---

# US-009 · Câmera em shift-lock com trava de alvo e boneco de treino

## História
**Como** jogador no PC,
**quero** entrar no modo combate (shift-lock) e travar a câmera num alvo, trocando e soltando quando quiser,
**para que** eu mire sem perder o alvo de vista.

## Contexto
Aba [Câmera e Mira](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f5514f82-709f): terceira pessoa, shift-lock que trava num alvo, e as habilidades de área continuam acertando todos (decisão do Davi, 04/11). A câmera e a trava são só do cliente; o servidor nunca confia nelas ([ADR-002](../../arquitetura/adr/ADR-002-servidor-autoritativo.md)). As teclas e o comportamento do shift-lock são perguntas abertas da aba: aqui entram valores provisórios, no Config.

## Critérios de aceite
**Cenário 1: modo combate (shift-lock)**
- **Dado** o jogador fora de combate
- **Quando** ele aperta a tecla do modo combate (provisória: Ctrl esquerdo)
- **Então** o mouse fica preso no centro, a câmera vai para o ombro e o personagem vira para onde a câmera aponta; apertar de novo desliga

**Cenário 2: travar num alvo**
- **Dado** um boneco de treino à frente, dentro do alcance de trava
- **Quando** o jogador aperta a tecla de travar (provisória: T ou o botão do meio do mouse)
- **Então** o boneco ganha um contorno, o modo combate liga, e a câmera e o personagem passam a acompanhá-lo

**Cenário 3: trocar e soltar**
- **Dado** um alvo travado
- **Quando** o jogador aperta Tab, **então** a trava passa para outro alvo válido, se houver
- **Quando** ele aperta a tecla de travar de novo, desliga o modo combate, ou o alvo morre, sai do alcance ou fica sem linha de visão por um tempo, **então** a trava solta

**Cenário 4: zoom limitado**
- **Dado** o jogador em qualquer modo
- **Quando** ele usa a rodinha do mouse
- **Então** o zoom fica entre o mínimo e o máximo do Config

**Cenário 5: boneco de treino**
- **Dado** um place sem nenhum modelo com a tag `Alvo`
- **Quando** o servidor inicia
- **Então** aparece um boneco de treino perto do spawn, e ele volta depois de um tempo se for derrubado

## Notas técnicas (arquiteto → dev)
- Lado: cliente (câmera e trava) e servidor (boneco)
- Módulos afetados: `src/client/Controllers/CameraController.luau`, `src/client/Controllers/TargetController.luau`, `src/server/Services/TrainingDummyService.luau`, `src/shared/Alvos.luau`, `src/shared/Config/Camera.luau` e `Treino.luau`
- Alvos são Models com Humanoid e a tag `Alvo` (CollectionService); outros jogadores também podem ser travados (provisório: a pergunta de PvP está aberta na aba)
- O shift-lock padrão do Roblox fica desligado (`StarterPlayer.EnableMouseLockOption`), porque o Shift é a corrida
- O boneco é um placeholder criado por código; modelos de verdade são feitos no Studio e só precisam da tag `Alvo`
- Remotes e validação no servidor: nenhum nesta história
- Dados persistidos: nenhum

## Tarefas
- [x] Zoom mínimo e máximo pelo Config
- [x] Modo combate: mouse no centro, câmera no ombro, personagem virado para a câmera
- [x] Trava: escolher o alvo mais perto do centro da câmera, contorno, trocar e soltar
- [x] Boneco de treino com a tag `Alvo`, que volta depois de derrubado
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-05):** o Davi pediu em 05/11 para começar o código.
- **`CameraController`:** zoom limitado pelo Config e o modo combate. No modo combate, o mouse fica preso no centro, a câmera vai para o ombro e o personagem vira para onde a câmera aponta. Com um alvo travado, a câmera fica atrás do ombro olhando para o alvo, e o personagem vira para ele.
- **`TargetController`:** travar escolhe o alvo vivo, no alcance, visível e mais perto do centro da câmera, desenha um contorno nele e liga o modo combate. A tecla de trocar passa para outro alvo. A trava solta quando o alvo morre, sai do alcance, fica sem visão por um tempo, quando se trava de novo ou quando o modo combate desliga.
- **`TrainingDummyService`:** se o place não tiver nenhum modelo com a tag `Alvo`, cria um boneco de treino 20 studs à frente do SpawnLocation. Derrubado, ele volta depois de 5 s.
- **`Shared.Alvos`:** diz o que é alvo (Model com Humanoid e a tag) e onde ele está.
- **`default.project.json`:** desliga o shift-lock padrão do Roblox (`EnableMouseLockOption`), porque o Shift é a corrida.

**Comportamentos provisórios** (perguntas abertas da aba Câmera e Mira, ajustáveis em `Config/Camera`):
- Ctrl liga e desliga o modo combate; T ou o botão do meio do mouse trava e solta; Tab troca de alvo.
- Travar liga o modo combate; soltar não desliga.
- A trava pega outros jogadores (`TRAVA_PEGA_JOGADORES`).
- O Tab também abre a lista de jogadores do Roblox. Se incomodar, troque a tecla no Config.

**Limitações conhecidas desta primeira versão:**
- Com alvo travado, a câmera ignora o mouse e pode atravessar paredes, porque não passa pela proteção de oclusão da câmera padrão.
- Ao soltar a trava, a câmera volta para o ângulo de antes.
- Trocar de alvo alterna entre os dois mais perto do centro.

**Para o Davi testar no Studio:**
1. **Cenário 5:** dê Play. Um "Boneco de treino" aparece à frente do spawn, com o nome em cima.
2. **Cenário 1:** aperte Ctrl. O mouse some no centro, a câmera vai para o ombro direito e o personagem gira com a câmera. Ande com WASD olhando em volta, depois aperte Ctrl de novo para sair.
3. **Cenário 2:** olhe para o boneco e aperte T (ou o botão do meio do mouse). Ele ganha um contorno amarelo, e a câmera e o personagem passam a segui-lo. Ande em círculo em volta dele.
4. **Cenário 3:** aperte T de novo para soltar. Trave de novo e:
   - afaste-se além de 60 studs;
   - ou esconda o boneco atrás de uma parede por 1,5 s;
   - ou aperte Ctrl.

   Em cada caso a trava solta. Com 2 jogadores (Test → Clients and Servers → 2 players), Tab passa a trava do boneco para o outro jogador.
5. **Cenário 4:** use a rodinha do mouse. O zoom para entre 6 e 22 studs.
6. **Boneco volta:** na barra de comandos do servidor, rode `workspace["Boneco de treino"].Humanoid.Health = 0`. Ele some e volta 5 s depois.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
