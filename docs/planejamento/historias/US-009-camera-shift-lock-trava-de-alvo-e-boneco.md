---
tipo: historia
id: US-009
titulo: Câmera em shift-lock com trava de alvo e boneco de treino
status: backlog
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
- [ ] Zoom mínimo e máximo pelo Config
- [ ] Modo combate: mouse no centro, câmera no ombro, personagem virado para a câmera
- [ ] Trava: escolher o alvo mais perto do centro da câmera, contorno, trocar e soltar
- [ ] Boneco de treino com a tag `Alvo`, que volta depois de derrubado
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [ ] Atualizar a documentação afetada

## Revisão / resultado
*Preenchido pelo dev ao terminar: o que foi feito, o que ficou de fora, como testar no Studio, PR.*
