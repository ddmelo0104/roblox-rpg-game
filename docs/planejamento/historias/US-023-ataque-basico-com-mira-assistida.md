---
tipo: historia
id: US-023
titulo: Ataque básico com mira assistida
status: revisao
prioridade: must
epico: EP-003
pontos: 3
sprint:
criado: 2026-11-23
atualizado: 2026-11-23
concluido_em:
---

# US-023 · Ataque básico com mira assistida

## História
**Como** jogador,
**quero** um ataque básico no botão esquerdo, que acerte o alvo travado ou o inimigo à frente,
**para que** eu sempre tenha o que fazer, mesmo sem energia.

## Contexto
Aba [Combate e Habilidades](https://claude.ai/artifact/J9zY7LF95U87AhXJN5X6iQ#f0d54cbd-810d): o ataque básico tem mira assistida. Ele vai no alvo travado ou, sem trava, no inimigo mais próximo num cone à frente, e não gasta energia. As duas regras eram propostas da aba, adotadas pelo dev ([registro de decisões delegadas](../DECISOES-DELEGADAS.md)).

## Critérios de aceite
**Cenário 1: com trava**
- **Dado** um boneco travado no alcance da arma
- **Quando** o jogador clica com o botão esquerdo
- **Então** o boneco leva o dano do ataque básico, sem gastar energia

**Cenário 2: sem trava**
- **Dado** um boneco à frente, dentro do cone
- **Quando** o jogador clica
- **Então** o ataque acerta o boneco mais próximo do cone

**Cenário 3: ritmo**
- **Dado** cliques seguidos
- **Quando** o jogador clica sem parar
- **Então** o ataque sai no ritmo da arma (por exemplo, a cada 0,9 s na espada)

## Notas técnicas (arquiteto → dev)
- Lado: servidor e cliente
- Módulos afetados: `CombatService` (`basicAttack`), `CombatController`, `Shared.Abilities.isInCone`, `BASIC_ATTACK` nos Configs das armas
- Remotes e validação no servidor: `RequestBasicAttack(alvo?)`: o servidor confere o alvo, ou escolhe pelo cone, além do ritmo, do alcance e da linha de visão
- Dados persistidos: nenhum

## Tarefas
- [x] Implementar
- [ ] Testar no Studio (cenários acima), com servidor e cliente
- [x] Atualizar a documentação afetada

## Revisão / resultado
**Feito pelo dev (2026-11-23):** cada arma tem alcance, dano, ritmo e cone próprios em `BASIC_ATTACK`. O servidor escolhe o alvo: o travado, se estiver válido e no alcance; se não, o mais próximo no cone à frente, com linha de visão. Também confere o ritmo, aplica o multiplicador de dano do equipamento e põe o jogador em combate. Todos os clientes desenham uma linha até o alvo.

**Para o Davi testar no Studio:**
1. **Com trava:** trave um boneco e clique com o botão esquerdo. O dano sobe, e a energia não muda.
2. **Sem trava:** solte a trava, vire para um boneco e clique. Ele é acertado pelo cone.
3. **Ritmo:** clique sem parar. O ataque sai no ritmo da arma.

Passando, mude `status` para `concluido` e preencha `concluido_em`.
